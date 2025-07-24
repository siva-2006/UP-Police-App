// lib/qr_scan_page.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Import mobile_scanner
import 'package:permission_handler/permission_handler.dart'; // For permission handling
import 'package:eclub_app/app_themes.dart'; // For theme colors

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key}); // Added const constructor

  @override
  State<QrScanPage> createState() => _QrScanPageState(); // Changed to createState
}

class _QrScanPageState extends State<QrScanPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isTorchOn = false; // Renamed to _isTorchOn for consistency
  String _scanMode = 'scan'; // Renamed to _scanMode for consistency
  String _qrCodeResult = "Scan a QR code"; // To display scanned result

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    PermissionStatus cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied. Cannot scan QR codes.')),
      );
    }
  }

  // Helper widget for the bottom mode toggle buttons
  Widget _buildModeButton(String mode, IconData icon, double screenWidth) {
    bool isSelected = _scanMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _scanMode = mode;
            // TODO: Implement logic for switching between scan/photo mode if needed
            // For now, it's just a visual toggle.
            print('Scan mode changed to: $mode');
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).cardColor, // Themed colors
            border: Border.all(color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.grey.shade700), // Themed border
            borderRadius: BorderRadius.circular(20), // Reduced radius for a less circular look
          ),
          child: Center(
            child: Icon(
              icon,
              color: Theme.of(context).textTheme.bodyLarge?.color, // Themed icon color
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    const double headerFixedPxHeight = 70.0;
    const double cameraPreviewHeight = 300.0; // Fixed height for camera preview area
    const double flashlightButtonDiameter = 50.0;
    const double callPoliceButtonHeight = 65.0;
    const double bottomButtonsRowHeight = 60.0; // Height for the bottom toggle buttons

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Flat Header
            Container(
              height: headerFixedPxHeight,
              width: screenWidth,
              color: AppThemes.darkBlue,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                      onPressed: () { print('Profile Icon Pressed from QR Scan'); },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/image_6d3861.png',
                          height: headerFixedPxHeight * 0.6,
                          width: headerFixedPxHeight * 0.6 * (11/7),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ASTRA',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                      onPressed: () { print('Settings Icon Pressed from QR Scan'); },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30.0), // Space below header

            // QR Scanner Area
            Container(
              width: screenWidth * 0.8, // 80% of screen width
              height: cameraPreviewHeight, // Fixed height for camera preview
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // Themed background for the scanner box
                borderRadius: BorderRadius.circular(20), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect( // Clip the scanner preview to match container's border radius
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      debugPrint('Barcode found! Type: ${barcode.type}, Value: ${barcode.rawValue}');
                      setState(() {
                        _qrCodeResult = barcode.rawValue ?? 'No value';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Scanned: $_qrCodeResult')),
                      );
                      // You can add logic here to navigate, save, or process the QR code.
                      // cameraController.stop(); // Uncomment to stop scanning after first detection
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20.0), // Space below scanner

            // Torch Button
            Container(
              width: flashlightButtonDiameter,
              height: flashlightButtonDiameter,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, // Themed surface color
                borderRadius: BorderRadius.circular(15), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
                  color: Theme.of(context).textTheme.bodyLarge?.color, // Themed icon color
                  size: 28,
                ),
                onPressed: () async {
                  await cameraController.toggleTorch();
                  setState(() {
                    _isTorchOn = !_isTorchOn;
                  });
                },
              ),
            ),
            // const SizedBox(height: 10.0), // Removed this SizedBox, let Spacer handle

            Spacer(), // Flexible space to push content up

            // Call Police Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: Container(
                width: double.infinity,
                height: callPoliceButtonHeight,
                decoration: BoxDecoration(
                  color: AppThemes.emergencyRed,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemes.emergencyRed.withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: MaterialButton(
                  onPressed: () { print('CALL POLICE Pressed!'); },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: const Text(
                    'CALL POLICE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15.0), // Space before bottom toggle buttons

            // Bottom Toggle Buttons (Scan/Photo)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: SizedBox(
                height: bottomButtonsRowHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildModeButton('scan', Icons.qr_code_scanner, screenWidth),
                    _buildModeButton('photo', Icons.camera_alt, screenWidth),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15.0), // Bottom padding
          ],
        ),
      ),
    );
  }
}