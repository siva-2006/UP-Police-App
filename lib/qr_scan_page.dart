import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'app_themes.dart';

class QrScanPage extends StatefulWidget {
  final String initialScanMode;

  const QrScanPage({
    super.key,
    this.initialScanMode = 'scan',
  });

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> with WidgetsBindingObserver {
  final MobileScannerController _qrController = MobileScannerController();
  CameraController? _photoController;
  List<CameraDescription>? _cameras;
  XFile? _capturedImageFile;

  late String _scanMode;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  Map<String, dynamic>? _driverData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanMode = widget.initialScanMode;

    if (_scanMode == 'photo') {
      _initializePhotoCamera();
    }
  }

  Future<void> _initializePhotoCamera() async {
    // Ensure the QR scanner is not running
    if (_qrController.isStarting) {
      await _qrController.stop();
    }
    
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _photoController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
      );
      await _photoController!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  // CORRECTED: This function is now async to handle camera resource management properly.
  Future<void> _setScanMode(String mode) async {
    if (_scanMode == mode) return;

    if (mode == 'photo') {
      // Stop QR scanner and initialize photo camera
      await _qrController.stop();
      await _initializePhotoCamera();
    } else {
      // Dispose photo camera and start QR scanner
      await _photoController?.dispose();
      _photoController = null;
      // Let the MobileScanner widget restart the controller automatically
    }

    if (mounted) {
      setState(() {
        _scanMode = mode;
        _isProcessing = false;
        _capturedImageFile = null;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_scanMode == 'scan') return;

    final controller = _photoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializePhotoCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _qrController.dispose();
    _photoController?.dispose();
    super.dispose();
  }

  void _retakePhoto() {
    setState(() {
      _capturedImageFile = null;
      _isProcessing = false;
    });
  }
  
  void _sendEvidence() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evidence sent. Reporting feature coming soon.')),
    );
    // This will now correctly await the camera resource handover
    _setScanMode('scan');
  }

  void _startScanning() {
    _setScanMode('scan');
    setState(() {
      _driverData = null;
    });
  }

  Future<void> _fetchDriverDetails(String driverId) async {
    setState(() {
      _isProcessing = true;
    });

    final String apiUrl = 'http://192.168.137.1:5000/api/driver/data/$driverId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (kDebugMode) {
          print('Driver details fetched: $data');
        }
        if(mounted) setState(() => _driverData = data);
      } else {
        if (kDebugMode) print('Failed to load driver details. Status code: ${response.statusCode}');
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get driver details: ${response.statusCode}')));
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching driver details: $e');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Could not connect to server.')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildDriverDetailsView() {
    if (_driverData == null) return const SizedBox.shrink();
    
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Driver Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 10),
              _buildDetailRow('First Name', _driverData!['firstName']),
              _buildDetailRow('Last Name', _driverData!['lastName']),
              _buildDetailRow('Vehicle Number', _driverData!['vehicleNum']),
              _buildDetailRow('Mobile', _driverData!['mobile']),
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
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
          Expanded(child: Text(value?.toString() ?? 'N/A', style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_scanMode == 'scan' ? 'Scan QR Code' : 'Take Photo'),
        backgroundColor: AppThemes.darkBlue,
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
              if (_scanMode == 'scan') {
                _qrController.toggleTorch();
              } else {
                _photoController?.setFlashMode(_isTorchOn ? FlashMode.torch : FlashMode.off);
              }
            },
            icon: Icon(_isTorchOn ? Icons.flashlight_on : Icons.flashlight_off, color: _isTorchOn ? Colors.yellow : Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildCameraView()),
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.black.withOpacity(0.8),
              child: _capturedImageFile != null ? _buildPhotoControls() : _buildCameraControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_capturedImageFile != null) return Image.file(File(_capturedImageFile!.path), fit: BoxFit.cover);
    if (_driverData != null) return _buildDriverDetailsView();

    if (_scanMode == 'scan') {
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
          if (_isProcessing) const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(12)),
          ),
        ],
      );
    } else {
      if (_photoController == null || !_photoController!.value.isInitialized) return const Center(child: CircularProgressIndicator());
      return CameraPreview(_photoController!);
    }
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildModeButton('scan', Icons.qr_code_scanner),
        if (_scanMode == 'photo')
          GestureDetector(
            onTap: () async {
              if (_photoController == null || !_photoController!.value.isInitialized) return;
              try {
                final XFile image = await _photoController!.takePicture();
                if(mounted) setState(() => _capturedImageFile = image);
              } catch (e) {
                if (kDebugMode) print("Error taking picture: $e");
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
            ),
          ),
        _buildModeButton('photo', Icons.camera),
      ],
    );
  }

  Widget _buildPhotoControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _retakePhoto,
          icon: const Icon(Icons.refresh),
          label: const Text('Retake'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
        ),
        ElevatedButton.icon(
          onPressed: _sendEvidence,
          icon: const Icon(Icons.send),
          label: const Text('Send Evidence'),
          style: ElevatedButton.styleFrom(backgroundColor: AppThemes.emergencyRed, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildModeButton(String mode, IconData icon) {
    bool isSelected = _scanMode == mode;
    return IconButton(
      onPressed: () => _setScanMode(mode),
      icon: Icon(icon, color: isSelected ? AppThemes.tealGreen : Colors.white, size: 30),
    );
  }
}