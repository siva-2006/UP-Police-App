// lib/welcome_home_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart'; //
import 'package:eclub_app/home_dashboard_screen.dart'; //
import 'package:eclub_app/main.dart';
import 'package:eclub_app/qr_scan_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeHomeScreen extends StatefulWidget {
  const WelcomeHomeScreen({super.key}); //

  @override
  State<WelcomeHomeScreen> createState() => _WelcomeHomeScreenState();
}

class _WelcomeHomeScreenState extends State<WelcomeHomeScreen> {
  String _userName = "User"; //
  bool _isLoading = true; //
  bool _isSafeModeActive = false; //

  // --- FIX APPLIED HERE ---
  @override
  void initState() {
    super.initState();
    // Add a listener that will call setState() to rebuild the widget
    languageNotifier.addListener(_onLanguageChanged);
    _loadUserName();
  }

  @override
  void dispose() {
    // Remove the listener to prevent memory leaks
    languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {
      // This empty setState call is enough to trigger a rebuild
    });
  }
  // --- END OF FIX ---

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
      if (await canLaunchUrl(smsLaunchUri)) {
        await launchUrl(smsLaunchUri);
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  color: AppThemes.darkBlue, //
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Center(
                  child: Text('ASTRA', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontSize: 36)),
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
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScanPage())), //
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, size: bottomIconSize),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScanPage())), //
                  ),
                  IconButton(
                    icon: Icon(Icons.menu, size: bottomIconSize),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeDashboardScreen())), //
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              setState(() => _isSafeModeActive = true);
            } else {
              _sendSms('112', 'Emergency! I am in danger and need help.');
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSafeModeActive ? AppThemes.emergencyRed : Colors.blue.shade800, //
              boxShadow: [ BoxShadow(color: (_isSafeModeActive ? AppThemes.emergencyRed : Colors.blue).withOpacity(0.5), blurRadius: 25, spreadRadius: 5) ], //
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
        const SizedBox(height: 40.0),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: _isSafeModeActive ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !_isSafeModeActive,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 60,
              child: ElevatedButton(
                onPressed: () => setState(() => _isSafeModeActive = false),
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
}