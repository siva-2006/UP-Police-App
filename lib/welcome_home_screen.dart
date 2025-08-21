import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/home_dashboard_screen.dart';
import 'package:eclub_app/main.dart';
import 'package:eclub_app/qr_scan_page.dart';
import 'package:eclub_app/scream_detection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eclub_app/location_service.dart';
import 'package:permission_handler/permission_handler.dart';

class WelcomeHomeScreen extends StatefulWidget {
  const WelcomeHomeScreen({super.key});

  @override
  State<WelcomeHomeScreen> createState() => _WelcomeHomeScreenState();
}

class _WelcomeHomeScreenState extends State<WelcomeHomeScreen> {
  String _userName = "User";
  bool _isLoading = true;
  bool _isSafeModeActive = false;
  // REVERTED: Create the instance here again
  late final ScreamDetectionService _screamService;
  late final LocationService _locationService;
  bool _isDialogShowing = false;

  final ValueNotifier<String> _callPoliceStatusNotifier = ValueNotifier('');
  Timer? _callPoliceTimer;

  @override
  void initState() {
    super.initState();
    // REVERTED: Initialize the service here
    _screamService = ScreamDetectionService();
    _locationService = LocationService();
    languageNotifier.addListener(_onLanguageChanged);
    _loadUserName();
    _requestAllPermissions();
  }

  Future<void> _requestAllPermissions() async {
    final permissions = {
      Permission.sms: 'For sending emergency messages automatically.',
      Permission.location: 'To send your location during an emergency.',
      Permission.microphone: 'For the scream detection feature.',
      Permission.camera: 'To scan QR codes and capture evidence.',
      Permission.contacts: 'To select emergency contacts.',
      Permission.notification: 'To show confirmation alerts.',
    };

    for (var permission in permissions.entries) {
      final status = await permission.key.status;
      if (status.isDenied) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('${permission.key.toString().split('.').last.capitalize()} Permission Required'),
              content: Text('Jagriti Suraksha requires this permission:\n\n${permission.value}'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await permission.key.request();
                  },
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _showScreamDetectedDialog() {
    if (_isDialogShowing) return;
    setState(() => _isDialogShowing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isHindi = languageNotifier.isHindi;
        return AlertDialog(
          title: Text(isHindi ? 'चीख का पता चला!' : 'Scream Detected!'),
          content: Text(isHindi
              ? 'यदि यह एक झूठा अलार्म है, तो अलर्ट रद्द करने के लिए सूचना को खारिज कर दें।'
              : 'If this is a false alarm, dismiss the notification to cancel the alert.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(isHindi ? 'ठीक है' : 'OK')),
          ],
        );
      },
    ).then((_) => setState(() => _isDialogShowing = false));
  }


  @override
  void dispose() {
    languageNotifier.removeListener(_onLanguageChanged);
    _screamService.dispose();
    _callPoliceStatusNotifier.dispose();
    _callPoliceTimer?.cancel();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'User';
        if (_userName.isNotEmpty) {
           _userName = _userName[0].toUpperCase() + _userName.substring(1).toLowerCase();
        }
        _isLoading = false;
      });
    }
  }

  String _getGreeting(bool isHindi) {
    final hour = DateTime.now().hour;
    if (hour < 12) return isHindi ? 'सुप्रभात' : 'GOOD MORNING';
    if (hour < 17) return isHindi ? 'नमस्कार' : 'GOOD AFTERNOON';
    if (hour < 21) return isHindi ? 'शुभ संध्या' : 'GOOD EVENING';
    return isHindi ? 'शुभ रात्रि' : 'GOOD NIGHT';
  }
  
  void _handleCallPolicePress() {
    notificationService.showCallPoliceConfirmationNotification(onCancel: () {
      _callPoliceStatusNotifier.value = "Cancelled by user";
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _callPoliceStatusNotifier.value = "";
      });
    });

    int countdown = 30;
    _callPoliceStatusNotifier.value = "Activating in $countdown...";
    _callPoliceTimer?.cancel();
    _callPoliceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown--;
      if (countdown <= 0) {
        timer.cancel();
        _callPoliceStatusNotifier.value = "Activated!";
        Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _callPoliceStatusNotifier.value = "";
        });
      } else if (_callPoliceStatusNotifier.value.contains("Cancelled")) {
        timer.cancel();
      }
      else {
        if (mounted) _callPoliceStatusNotifier.value = "Activating in $countdown...";
      }
    });
  }

  Future<void> _toggleSafeMode(bool isActive) async {
    setState(() => _isSafeModeActive = isActive);
    
    if (isActive) {
      final prefs = await SharedPreferences.getInstance();
      final isScreamDetectionEnabled = prefs.getBool('screamDetectionEnabled') ?? true;
      if (isScreamDetectionEnabled) {
        _screamService.start();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scream detection is off. Turn it on in More Settings.')),
        );
      }
    } else {
      _screamService.stop();
      _locationService.stopTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, child) {
        final isHindi = languageNotifier.isHindi;
        final screenWidth = MediaQuery.of(context).size.width;
        final double welcomeFontSize = screenWidth * 0.055;
        final double bottomIconSize = screenWidth * 0.1;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                Hero(
                  tag: 'astra_header',
                  child: Container(
                    height: 120,
                    width: screenWidth,
                    decoration: const BoxDecoration(
                      color: AppThemes.darkBlue,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
                    ),
                    child: Center(
                      child: Text(
                        isHindi ? 'जागृति सुरक्षा' : 'Jagriti Suraksha',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontSize: 36),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50.0),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      '${_getGreeting(isHindi)}, ${_userName.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontFamily: isHindi ? 'Mukta' : 'Inter',
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: welcomeFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                const Spacer(),
                _buildCentralButtonArea(isHindi),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner, size: bottomIconSize),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScanPage())),
                      ),
                      IconButton(
                        icon: Icon(Icons.camera_alt, size: bottomIconSize),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScanPage(initialScanMode: 'photo'))),
                      ),
                      IconButton(
                        icon: Icon(Icons.menu, size: bottomIconSize),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeDashboardScreen())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCentralButtonArea(bool isHindi) {
    final double buttonSize = MediaQuery.of(context).size.width * 0.55;
    const double buttonFontSize = 30.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (!_isSafeModeActive) {
              _toggleSafeMode(true);
            } else {
              _handleCallPolicePress();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSafeModeActive ? AppThemes.emergencyRed : Colors.blue.shade800,
              boxShadow: [ BoxShadow(color: (_isSafeModeActive ? AppThemes.emergencyRed : Colors.blue).withOpacity(0.5), blurRadius: 25, spreadRadius: 5) ],
            ),
            child: Center(
              child: Text(
                _isSafeModeActive ? (isHindi ? 'पुलिस को\nबुलाओ' : 'CALL\nPOLICE') : (isHindi ? 'सुरक्षित\nमोड' : 'SAFE\nMODE'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: buttonFontSize, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20.0),
        ValueListenableBuilder<String>(
          valueListenable: _screamService.statusNotifier,
          builder: (context, status, child) {
            if (status == "Scream Detected!") {
              WidgetsBinding.instance.addPostFrameCallback((_) => _showScreamDetectedDialog());
            }
            if (status.isEmpty) return const SizedBox(height: 24);
            
            Color statusColor;
            if (status.contains("Scream") || status.contains("Confirming") || status.contains("Activated")) statusColor = Colors.redAccent;
            else if (status.contains("Cancelled")) statusColor = Colors.green;
            else statusColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

            return _buildStatusBox(status, statusColor, isHindi);
          },
        ),
        ValueListenableBuilder<String>(
          valueListenable: _callPoliceStatusNotifier,
          builder: (context, status, child) {
            if (status.isEmpty) return const SizedBox.shrink();
            
            Color statusColor = status.contains("Cancelled") ? Colors.green : Colors.orangeAccent;
            
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildStatusBox(status, statusColor, isHindi, prefix: isHindi ? "मैनुअल अलर्ट:" : "MANUAL ALERT:"),
            );
          },
        ),
        const SizedBox(height: 20.0),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _isSafeModeActive ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !_isSafeModeActive,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 60,
              child: ElevatedButton(
                onPressed: () => _toggleSafeMode(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(isHindi ? "मैं सुरक्षित हूँ" : "I'M SAFE", style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBox(String status, Color color, bool isHindi, {String prefix = "STATUS:"}) {
    final hindiPrefix = prefix == "STATUS:" ? "स्टेटस:" : "मैनुअल अलर्ट:";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isHindi ? hindiPrefix : prefix,
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}