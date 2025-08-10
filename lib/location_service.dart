// lib/location_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  final Location _location = Location();
  Timer? _timer;
  String? _userPhone;
  
  final String _serverUrl = 'http://192.168.137.1:3000'; // <-- IMPORTANT: Replace with your server URL

  LocationService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userPhone = prefs.getString('user_phone');
  }

  Future<bool> _requestPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  void startTracking() async {
    if (_userPhone == null) {
      print("Cannot start tracking: user phone number not found.");
      return;
    }
    
    bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      print("Location permission denied. Cannot start tracking.");
      return;
    }

    // Send one immediate location update, then start the timer
    _sendLocationUpdate();
    
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _sendLocationUpdate();
    });
    print("Location tracking started...");
  }

  Future<void> _sendLocationUpdate() async {
    try {
      final locationData = await _location.getLocation();
      if (locationData.latitude == null || locationData.longitude == null) return;
      
      String address = "Address not found";
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(locationData.latitude!, locationData.longitude!);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          address = "${p.name}, ${p.locality}, ${p.postalCode}, ${p.country}";
        }
      } catch (e) {
        print("Could not get address: $e");
      }
      
      print("Sending location update: Lat: ${locationData.latitude}, Lng: ${locationData.longitude}, Address: $address");

      await http.post(
        Uri.parse('$_serverUrl/location/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': _userPhone,
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'address': address,
        }),
      );

    } catch (e) {
      print("Failed to send location update: $e");
    }
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    print("Location tracking stopped.");
  }
}