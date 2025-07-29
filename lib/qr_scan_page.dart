// lib/qr_scan_page.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:path_provider/path_provider.dart';

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
  // For QR Scanning
  final MobileScannerController _qrController = MobileScannerController();
  
  // For Photo Capture
  CameraController? _photoController;
  List<CameraDescription>? _cameras;
  XFile? _capturedImageFile;

  late String _scanMode;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanMode = widget.initialScanMode;
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _photoController = CameraController(_cameras![0], ResolutionPreset.high);
      await _photoController!.initialize();
      if (mounted) {
        setState(() {}); // Update UI once camera is initialized
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_photoController == null || !_photoController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _photoController!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
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
    _retakePhoto();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Camera previews look best on black
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
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
            icon: Icon(
              _isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
              color: _isTorchOn ? Colors.yellow : Colors.white,
            ),
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
              if (_isProcessing) return;
              if (capture.barcodes.isNotEmpty) {
                setState(() { _isProcessing = true; });
                final barcode = capture.barcodes.first;
                _qrController.stop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('QR Scanned: ${barcode.rawValue}')),
                );
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
    } else { // Photo Mode
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