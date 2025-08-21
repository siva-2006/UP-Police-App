import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_telephony/telephony.dart';

class EmergencyService {
  final String _serverUrl = 'http://192.168.137.1:3000';
  final Location _location = Location();
  final Telephony telephony = Telephony.instance;

  // This is the original function for scream detection
  Future<void> triggerScreamEmergencyActions() async {
    final LocationData? currentLocation = await _getCurrentLocation();
    if (currentLocation == null || currentLocation.latitude == null || currentLocation.longitude == null) {
      debugPrint("Could not get location. Aborting emergency actions.");
      return;
    }

    final lat = currentLocation.latitude!;
    final lon = currentLocation.longitude!;
    final String mapsUrl = "https://www.google.com/maps?q=$lat,$lon";

    await _sendLocationToPortal(lat, lon, "Scream Detected");

    final contacts = await _getEmergencyContacts();
    if (contacts.isEmpty) {
      debugPrint("No emergency contacts found to alert.");
      return;
    }

    final String message = "Emergency! A scream was detected. My current location is: $mapsUrl";
    final List<String> recipients = contacts.map((c) => c['phone'] as String).where((phone) => phone.isNotEmpty).toList();
    
    if (recipients.isNotEmpty) {
      await _sendSms(recipients, message);
    }
  }

  // UPDATED: This function now also sends SMS to emergency contacts
  Future<void> triggerCallPoliceAction() async {
    debugPrint("Triggering 'Call Police' action...");
    final LocationData? currentLocation = await _getCurrentLocation();
    if (currentLocation == null || currentLocation.latitude == null || currentLocation.longitude == null) {
      debugPrint("Could not get location for 'Call Police' action.");
      return;
    }

    final lat = currentLocation.latitude!;
    final lon = currentLocation.longitude!;
    final String mapsUrl = "https://www.google.com/maps?q=$lat,$lon";

    // Send location to the backend
    await _sendLocationToPortal(lat, lon, "Call Police Button Pressed");

    // Also send SMS to emergency contacts
    final contacts = await _getEmergencyContacts();
    if (contacts.isEmpty) {
      debugPrint("No emergency contacts found to alert.");
      return;
    }

    final String message = "Emergency! The Call Police button was activated. My current location is: $mapsUrl";
    final List<String> recipients = contacts.map((c) => c['phone'] as String).where((phone) => phone.isNotEmpty).toList();

    if (recipients.isNotEmpty) {
      await _sendSms(recipients, message);
    }
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
          'latitude': lat,
          'longitude': lon,
          'address': address,
          'triggerReason': triggerReason,
          'timestamp': DateTime.now().toIso8601String(),
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