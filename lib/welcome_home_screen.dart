// lib/welcome_home_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/home_dashboard_screen.dart';
import 'package:eclub_app/main.dart';
import 'package:eclub_app/qr_scan_page.dart'; // Import QrScanPage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeHomeScreen extends StatefulWidget {
  const WelcomeHomeScreen({super.key});

  @override
  State<WelcomeHomeScreen> createState() => _WelcomeHomeScreenState();
}

class _WelcomeHomeScreenState extends State<WelcomeHomeScreen> {
  String _userName = "User";
  bool _isLoading = true;
  bool _isSafeModeActive = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && userDoc.exists && userDoc.data()!.containsKey('name')) {
          final name = userDoc.data()!['name'] as String;
          if (name.isNotEmpty) {
            _userName = name[0].toUpperCase() + name.substring(1).toLowerCase();
          }
        }
      }
    } catch (e) {
      print("Error loading user name: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getGreeting(bool isHindi) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return isHindi ? 'सुप्रभात' : 'GOOD MORNING';
    } else if (hour < 17) {
      return isHindi ? 'नमस्कार' : 'GOOD AFTERNOON';
    } else if (hour < 21) {
      return isHindi ? 'शुभ संध्या' : 'GOOD EVENING';
    } else {
      return isHindi ? 'शुभ रात्रि' : 'GOOD NIGHT';
    }
  }

  Future<void> _sendSms(String phoneNumber, String message) async {
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{'body': Uri.encodeComponent(message)},
    );
    try {
      if (!mounted) return;
      if (await canLaunchUrl(smsLaunchUri)) {
        await launchUrl(smsLaunchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch SMS app.')),
        );
      }
    } catch (e) {
      print('Error launching SMS: $e');
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
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'ASTRA',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 36,
                            ),
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
                            letterSpacing: 1.2,
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
                        onPressed: () {
                          // --- NAVIGATE TO SCAN MODE ---
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScanPage(initialScanMode: 'scan')));
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.camera_alt, size: bottomIconSize),
                        onPressed: () {
                          // --- NAVIGATE TO PHOTO MODE ---
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScanPage(initialScanMode: 'photo')));
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.menu, size: bottomIconSize),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeDashboardScreen()),
                          );
                        },
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
    final double innerButtonSize = buttonSize * 0.85;
    const double buttonFontSize = 30.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (!_isSafeModeActive) {
              setState(() => _isSafeModeActive = true);
            } else {
              _sendSms('112', 'Emergency! I am in danger and need help.');
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: _isSafeModeActive
                      ? AppThemes.emergencyRed.withOpacity(0.5)
                      : Colors.blue.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.3 : 0.5),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: innerButtonSize,
                height: innerButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSafeModeActive ? AppThemes.emergencyRed : Colors.blue.shade800,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isSafeModeActive ? (isHindi ? 'पुलिस को\nबुलाओ' : 'CALL\nPOLICE') : (isHindi ? 'सुरक्षित\nमोड' : 'SAFE\nMODE'),
                      key: ValueKey<bool>(_isSafeModeActive),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: isHindi ? 'Mukta' : 'Inter',
                        color: Colors.white,
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40.0),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _isSafeModeActive ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !_isSafeModeActive,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _isSafeModeActive = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isHindi ? 'सुरक्षित मोड निष्क्रिय' : 'Safe Mode Deactivated')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isHindi ? "मैं सुरक्षित हूँ" : "I'M SAFE",
                    style: TextStyle(
                      fontFamily: isHindi ? 'Mukta' : 'Inter',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}