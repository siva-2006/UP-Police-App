import 'dart:async'; // ADD THIS LINE
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';

class EmergencyService {
  final String _serverUrl = 'https://340a2c6ff635.ngrok-free.app';
  final Location _location = Location();
  final Telephony telephony = Telephony.instance;

  Timer? _alertTimer;

  Future<void> triggerScreamEmergencyActions() async {
    _startPeriodicAlerts(triggerReason: "Scream Detected");
  }

  Future<void> triggerCallPoliceAction() async {
    _startPeriodicAlerts(triggerReason: "Call Police Button Pressed");
  }

  Future<void> _startPeriodicAlerts({required String triggerReason}) async {
    _alertTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    final frequency = int.tryParse(prefs.getString('locationFrequency') ?? '30') ?? 30;
    
    int alertCount = 0;
    const maxAlerts = 5;

    _alertTimer = Timer.periodic(Duration(seconds: frequency), (timer) async {
      if (alertCount >= maxAlerts) {
        timer.cancel();
        debugPrint("Finished sending periodic alerts.");
        return;
      }

      alertCount++;
      debugPrint("Sending alert #$alertCount for reason: $triggerReason");

      final LocationData? currentLocation = await _getCurrentLocation();
      if (currentLocation == null || currentLocation.latitude == null || currentLocation.longitude == null) {
        debugPrint("Could not get location for periodic alert.");
        return;
      }

      final lat = currentLocation.latitude!;
      final lon = currentLocation.longitude!;
      final String mapsUrl = "https://www.google.com/maps?q=$lat,$lon";

      await _sendLocationToPortal(lat, lon, triggerReason);

      final contacts = await _getEmergencyContacts();
      if (contacts.isEmpty) {
        debugPrint("No emergency contacts found for periodic alert.");
        return;
      }

      final message = triggerReason == "Scream Detected"
          ? "Emergency! A scream was detected. My current location is: $mapsUrl (Update #$alertCount)"
          : "Emergency! The Call Police button was activated. My current location is: $mapsUrl (Update #$alertCount)";
      
      final List<String> recipients = contacts.map((c) => c['phone'] as String).where((phone) => phone.isNotEmpty).toList();
      
      if (recipients.isNotEmpty) {
        await _sendSms(recipients, message);
      }
    });
  }

  void cancelPeriodicAlerts() {
    _alertTimer?.cancel();
    debugPrint("Periodic alerts have been cancelled by the user.");
  }

  Future<LocationData?> _getCurrentLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return null;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }
    
    return await _location.getLocation();
  }

  Future<void> _sendLocationToPortal(double lat, double lon, String triggerReason) async {
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('user_phone');
    final userName = prefs.getString('user_name');
    if (userPhone == null) return;

    String address = "Address not found";
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = "${p.name}, ${p.locality}, ${p.postalCode}, ${p.country}";
      }
    } catch (e) {
      debugPrint("Could not get address: $e");
    }

    try {
      await http.post(
        Uri.parse('$_serverUrl/location/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': userPhone,
          'name': userName,
          'latitude': lat,
          'longitude': lon,
          'address': address,
          'triggerReason': triggerReason,
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'new',
        }),
      );
      debugPrint("Successfully sent location to portal. Reason: $triggerReason");
    } catch (e) {
      debugPrint("Failed to send location to portal: $e");
    }
  }

  Future<List<dynamic>> _getEmergencyContacts() async {
    final box = Hive.box('emergency_contacts');
    final localContacts = box.get('contacts', defaultValue: []);
    return List<dynamic>.from(localContacts);
  }

  Future<void> _sendSms(List<String> recipients, String message) async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted != true) {
      debugPrint("SMS permissions not granted.");
      return;
    }
    for (String recipient in recipients) {
      try {
        await telephony.sendSms(to: recipient, message: message, isMultipart: true);
        debugPrint("SMS sent to $recipient");
      } catch (error) {
        debugPrint("Failed to send SMS to $recipient: $error");
      }
    }
  }
}