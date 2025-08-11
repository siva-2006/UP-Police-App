import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/driver_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Import for kDebugMode

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> with WidgetsBindingObserver {
  final MobileScannerController _qrController = MobileScannerController();

  // For Photo Capture
  CameraController? _photoController;
  List<CameraDescription>? _cameras;
  XFile? _capturedImageFile;

  String _scanMode = 'scan';
  bool _isProcessing = false;
  bool _isTorchOn = false;

  // --- NEW: State variable to store driver data ---
  Map<String, dynamic>? _driverData;

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

  // --- NEW: Function to reset state and start scanning again ---
  void _startScanning() {
    setState(() {
      _driverData = null; // Clear the driver data
      _isProcessing = false;
      _scanMode = 'scan';
    });
    _qrController.start();
  }

  // Function to fetch driver details from backend
  Future<void> _fetchDriverDetails(String driverId) async {
    setState(() {
      _isProcessing = true;
      // Clear data immediately when starting fetch to prevent stale data
      _driverData = null;
    });

    // Double-check the URL one last time
    final String apiUrl = 'http://172.23.46.13:5000/api/driver/data/$driverId'; // Adjusted URL: Removed /api/driver/data/

    if (kDebugMode) {
      print('--- _fetchDriverDetails started ---');
      print('Fetching from URL: $apiUrl');
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (kDebugMode) {
          print('Raw response body: ${response.body}');
          print('Parsed driver details data: $data');
        }

        setState(() {
          _driverData = data; // Set the state with fetched data
        });

        if (kDebugMode) {
          print('--- _driverData after setState: $_driverData ---');
        }

      } else {
        if (kDebugMode) {
          print('Failed to load driver details. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get driver details: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching driver details: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: Could not connect to server.')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _qrController.stop(); // Keep scanner stopped after fetching
      if (kDebugMode) {
        print('--- _fetchDriverDetails finished ---');
      }
    }
  }

  // --- NEW: Widget to display driver details on-screen ---
  Widget _buildDriverDetailsView() {
    // Add a print here to see if _driverData is null or populated when this is called
    if (kDebugMode) {
      print('Building Driver Details View. _driverData: $_driverData');
    }

    if (_driverData == null || _driverData!.isEmpty) { // Added .isEmpty check
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black, // Background color for the full screen when details are shown
      width: double.infinity,
      child: SingleChildScrollView( // Allow scrolling if content overflows
        padding: const EdgeInsets.all(20),
        child: Center( // Center the card itself
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make column only take required vertical space
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Driver Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130, // Fixed width for labels for alignment
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A', // Ensure value is converted to string
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
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
              color: Colors.black.withOpacity(0.8),
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

    // --- NEW: Check if driver data is available ---
    if (_driverData != null) {
      return _buildDriverDetailsView();
    }

    if (_scanMode == 'scan') {
      return Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _qrController,
            onDetect: (capture) {
<<<<<<< HEAD
              if (_isProcessing || capture.barcodes.isEmpty) return;
              final String? code = capture.barcodes.first.rawValue;
              if (code != null) {
                _handleScannedCode(code);
=======
              if (_isProcessing) return;
              if (capture.barcodes.isNotEmpty) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) {
                  setState(() {
                    _isProcessing = true;
                  });
                  _qrController.stop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('QR Scanned: ${barcode.rawValue}')),
                  );
                  _fetchDriverDetails(barcode.rawValue!);
                }
>>>>>>> e3a5e5c (changes)
              }
            },
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
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
                if (kDebugMode) {
                  print("Error taking picture: $e");
                }
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