import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_themes.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _qrController = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  Map<String, dynamic>? _driverData;

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _driverData = null;
      _isProcessing = false;
    });
    // The MobileScanner widget will automatically restart the controller
  }

  Future<void> _fetchDriverDetails(String driverId) async {
    setState(() {
      _isProcessing = true;
    });

    final String apiUrl = 'https://5a4d5b957470.ngrok-free.app/api/driver/data/$driverId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (kDebugMode) {
          print('Driver details fetched: $data');
        }
        await _addRideToHistory(data);
        if(mounted) setState(() => _driverData = data);
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get driver details: ${response.statusCode}')));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Could not connect to server.')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _addRideToHistory(Map<String, dynamic> driverDetails) async {
    final prefs = await SharedPreferences.getInstance();
    final String? userPhone = prefs.getString('user_phone');
    
    if (userPhone == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in. Please log in again.')));
      }
      return;
    }
      
    const String serverUrl = 'https://340a2c6ff635.ngrok-free.app';
    final String userApiUrl = '$serverUrl/user/$userPhone/rides';
    
    final rideData = {
      'name': '${driverDetails['firstName']} ${driverDetails['lastName']}',
      'vehicleNumber': driverDetails['vehicleNum'],
      'phone': driverDetails['mobile'],
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    try {
      final response = await http.post(
        Uri.parse(userApiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(rideData),
      );
    
      if (response.statusCode != 201) { // Backend returns 201 Created
        if (kDebugMode) print('Failed to save ride history. Status code: ${response.statusCode}');
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save ride history: ${response.statusCode}')));
      } else {
        if (kDebugMode) print('Ride history saved successfully.');
      }
    } catch (e) {
      if (kDebugMode) print('Error saving ride history: $e');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Could not connect to user database.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppThemes.darkBlue,
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
              _qrController.toggleTorch();
            },
            icon: Icon(_isTorchOn ? Icons.flashlight_on : Icons.flashlight_off, color: _isTorchOn ? Colors.yellow : Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: _driverData != null ? _buildDriverDetailsView() : _buildQrScanner(),
      ),
    );
  }

  Widget _buildQrScanner() {
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _qrController,
          onDetect: (capture) {
            if (_isProcessing || capture.barcodes.isEmpty) return;
            final barcode = capture.barcodes.first;
            if (barcode.rawValue != null) {
              _qrController.stop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR Scanned: ${barcode.rawValue}')));
              _fetchDriverDetails(barcode.rawValue!);
            }
          },
        ),
        if (_isProcessing)
          const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
        Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  // UPDATED: This widget is now theme-aware
  Widget _buildDriverDetailsView() {
    return Container(
      // Use the theme's scaffold background color for the backdrop
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Use the theme's card color for the box
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    // Use the theme's primary text color
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 10),
                _buildDetailRow('First Name', _driverData?['firstName']),
                _buildDetailRow('Last Name', _driverData?['lastName']),
                _buildDetailRow('Vehicle Number', _driverData?['vehicleNum']),
                _buildDetailRow('Mobile', _driverData?['mobile']),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _startScanning,
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  label: const Text('Scan Again', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemes.darkBlue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UPDATED: This widget now uses theme colors for text
  Widget _buildDetailRow(String label, dynamic value) {
    final textStyle = TextStyle(
      fontSize: 16,
      color: Theme.of(context).textTheme.bodyLarge?.color,
    );
    final labelStyle = textStyle.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text('$label:', style: labelStyle),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A', style: textStyle),
          ),
        ],
      ),
    );
  }
}