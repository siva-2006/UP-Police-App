// lib/qr_scan_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:eclub_app/app_themes.dart';

class QrScanPage extends StatefulWidget {
  final String initialScanMode;

  const QrScanPage({
    super.key,
    this.initialScanMode = 'scan',
  });

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _cameraController = MobileScannerController(
    returnImage: true, // Always return the image frame
  );
  late String _scanMode;
  Uint8List? _capturedImage;
  bool _isProcessing = false; // To prevent multiple detections at once

  @override
  void initState() {
    super.initState();
    _scanMode = widget.initialScanMode;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _isProcessing = false;
    });
    // Ensure the camera is running
    if (!_cameraController.isStarting) {
      _cameraController.start();
    }
  }

  void _usePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo saved. Reporting feature coming soon.')),
    );
    _retakePhoto();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_scanMode == 'scan' ? 'Scan QR Code' : 'Take Photo'),
        backgroundColor: AppThemes.darkBlue,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_capturedImage == null)
                    MobileScanner(
                      controller: _cameraController,
                      onDetect: (capture) {
                        if (_isProcessing) return; // Don't process new events if one is already being handled

                        // --- Logic for QR Scanning ---
                        if (_scanMode == 'scan' && capture.barcodes.isNotEmpty) {
                          setState(() { _isProcessing = true; });
                          final barcode = capture.barcodes.first;
                          _cameraController.stop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('QR Scanned: ${barcode.rawValue}')),
                          );
                        }
                        // --- Logic for Photo Capture ---
                        // Note: The actual capture is triggered by the button now
                      },
                    )
                  else
                    Image.memory(
                      _capturedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  if (_scanMode == 'scan' && _capturedImage == null)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.black.withOpacity(0.3),
              child: _capturedImage != null
                  ? _buildPhotoControls()
                  : _buildCameraControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildModeButton('scan', Icons.qr_code_scanner),
        if (_scanMode == 'photo')
          GestureDetector(
            onTap: () async {
              // Now, we listen for a single image from the stream
              final image = await _cameraController.barcodes.first.then((capture) => capture.image);
              if (image != null) {
                setState(() {
                  _capturedImage = image;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
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
          onPressed: _usePhoto,
          icon: const Icon(Icons.check),
          label: const Text('Use Photo'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppThemes.tealGreen,
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
          _isProcessing = false; // Reset processing flag when switching modes
          if (_cameraController.isStopped) {
            _cameraController.start();
          }
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