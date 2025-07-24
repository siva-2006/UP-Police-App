// lib/welcome_home_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/home_dashboard_screen.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    // --- Responsive Sizing ---
    final double buttonSize = screenWidth * 0.5;
    final double innerButtonSize = buttonSize * 0.85;
    final double buttonFontSize = screenWidth * 0.075;
    final double welcomeFontSize = screenWidth * 0.06;
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
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 36),
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
                  'GOOD MORNING, ${_userName.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: welcomeFontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
              ),

            const Spacer(),

            _buildCentralButtonArea(buttonSize, innerButtonSize, buttonFontSize),

            const Spacer(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner, size: bottomIconSize),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, size: bottomIconSize),
                    onPressed: () {},
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
  }

  Widget _buildCentralButtonArea(double buttonSize, double innerButtonSize, double fontSize) {
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
                      _isSafeModeActive ? 'CALL\nPOLICE' : 'SAFE\nMODE',
                      key: ValueKey<bool>(_isSafeModeActive),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
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
                      const SnackBar(content: Text('Safe Mode Deactivated')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "I'M SAFE",
                    style: TextStyle(
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