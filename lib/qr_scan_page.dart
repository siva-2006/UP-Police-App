// lib/qr_scan_page.dart
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/driver_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> with WidgetsBindingObserver {
  final MobileScannerController _qrController = MobileScannerController();
  CameraController? _photoController;
  List<CameraDescription>? _cameras;
  XFile? _capturedImageFile;

  String _scanMode = 'scan';
  bool _isProcessing = false;
  bool _isTorchOn = false;

  final String _serverUrl = 'http://192.168.137.1:3000';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePhotoCamera();
  }

  Future<void> _initializePhotoCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _photoController = CameraController(_cameras![0], ResolutionPreset.high, enableAudio: false);
      await _photoController!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final CameraController? cameraController = _photoController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
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

  Future<void> _handleScannedCode(String rawValue) async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; });
    _qrController.stop();

    try {
      final data = jsonDecode(rawValue) as Map<String, dynamic>;
      final driverDetails = {
        'name': data['name'] as String? ?? 'N/A',
        'vehicleNumber': data['vehicleNumber'] as String? ?? 'N/A',
        'phone': data['phone'] as String? ?? 'N/A',
      };
      
      if (driverDetails['name'] == 'N/A') {
        throw const FormatException("Missing 'name' in QR code.");
      }

      await _addRideToHistory(driverDetails);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DriverDetailsScreen(driverDetails: driverDetails),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid QR Code. Please try again.')),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if(mounted) {
            _qrController.start();
            setState(() { _isProcessing = false; });
          }
        });
      }
    }
  }
  
  Future<void> _addRideToHistory(Map<String, String> driverDetails) async {
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('user_phone');
    if (userPhone == null) return;
    
    await http.post(
      Uri.parse('$_serverUrl/user/$userPhone/rides'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(driverDetails),
    );
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
    _retakePhoto();
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
              if (_scanMode == 'scan') {
                _qrController.toggleTorch();
              } else {
                _photoController?.setFlashMode(_isTorchOn ? FlashMode.off : FlashMode.torch);
              }
              setState(() { _isTorchOn = !_isTorchOn; });
            },
            icon: Icon(_isTorchOn ? Icons.flashlight_on : Icons.flashlight_off, color: _isTorchOn ? Colors.yellow : Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildCameraView(),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.black.withOpacity(0.5),
              child: _capturedImageFile != null
                  ? _buildPhotoControls()
                  : _buildCameraControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_capturedImageFile != null) {
      return Image.file(File(_capturedImageFile!.path), fit: BoxFit.cover);
    }
    
    if (_scanMode == 'scan') {
      return Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _qrController,
            onDetect: (capture) {
              if (_isProcessing || capture.barcodes.isEmpty) return;
              final String? code = capture.barcodes.first.rawValue;
              if (code != null) {
                _handleScannedCode(code);
              }
            },
          ),
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
    } else {
      if (_photoController == null || !_photoController!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
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
                setState(() {
                  _capturedImageFile = image;
                });
              } catch (e) {
                print("Error taking picture: $e");
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
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, foregroundColor: Colors.black),
        ),
        ElevatedButton.icon(
          onPressed: _sendEvidence,
          icon: const Icon(Icons.send),
          label: const Text('Send Evidence'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppThemes.emergencyRed,
              foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildModeButton(String mode, IconData icon) {
    bool isSelected = _scanMode == mode;
    return IconButton(
      onPressed: () {
        setState(() {
          _scanMode = mode;
          _isProcessing = false;
        });
      },
      icon: Icon(
        icon,
        color: isSelected ? AppThemes.tealGreen : Colors.white,
        size: 30,
      ),
    );
  }
}