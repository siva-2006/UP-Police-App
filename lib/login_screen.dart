// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/otp_verification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isHindi = false;
  bool _isLoading = false;
  String? _phoneErrorText;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePhoneNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_phone_number', phoneNumber);
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    final String phoneNumber = '+91${_phoneController.text.trim()}';
    final FirebaseAuth auth = FirebaseAuth.instance;

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
        setState(() { _isLoading = false; });
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() { _isLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send OTP: ${e.message}")),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() { _isLoading = false; });
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: _phoneController.text.trim(),
                verificationId: verificationId,
                resendToken: resendToken,
                isHindi: _isHindi,
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() { _isLoading = false; });
      },
    );
  }

  void _validateAndSendOtp() {
    if (_phoneController.text.trim().length == 10) {
      setState(() {
        _phoneErrorText = null;
      });
      _savePhoneNumber(_phoneController.text.trim());
      _sendOtp();
    } else {
      setState(() {
        _phoneErrorText = _isHindi
            ? 'कृपया एक मान्य 10-अंकीय फ़ोन नंबर दर्ज करें'
            : 'Enter valid 10-digit number';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive font sizes
    final double titleFontSize = screenWidth * 0.055;
    final double bodyFontSize = screenWidth * 0.04;

    final hindiTextStyle = TextStyle(fontFamily: 'Mukta', fontSize: bodyFontSize, color: Theme.of(context).textTheme.bodyLarge?.color);
    final hindiTitleStyle = TextStyle(fontFamily: 'Mukta', color: Theme.of(context).textTheme.headlineMedium?.color, fontSize: titleFontSize, fontWeight: FontWeight.bold);
    final hindiButtonStyle = const TextStyle(fontFamily: 'Mukta', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: screenHeight * 0.17,
                width: screenWidth,
                decoration: const BoxDecoration(
                  color: AppThemes.darkBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: Center(
                  child: Text(
                    'ASTRA',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 36),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                _isHindi ? 'लॉगिन/रजिस्टर' : 'LOGIN/REGISTER',
                style: _isHindi
                  ? hindiTitleStyle
                  : Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: titleFontSize),
              ),
              SizedBox(height: screenHeight * 0.03),
              Image.asset(
                'assets/images/image_6d3861.png',
                height: screenHeight * 0.19,
              ),
              SizedBox(height: screenHeight * 0.05),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: bodyFontSize),
                  decoration: InputDecoration(
                    counterText: "",
                    labelText: _isHindi ? 'मोबाइल नंबर' : 'Mobile Number',
                    errorText: _phoneErrorText,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [AppThemes.tealGreen, Colors.teal],
                    ),
                  ),
                  child: MaterialButton(
                    onPressed: _isLoading ? null : _validateAndSendOtp,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isHindi ? 'ओटीपी भेजें' : 'SEND OTP',
                            style: _isHindi ? hindiButtonStyle : const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.07),
              TextButton(
                onPressed: () => setState(() => _isHindi = !_isHindi),
                child: Text(
                  _isHindi ? 'Change Language' : 'भाषा बदलें',
                  style: (_isHindi ? TextStyle(fontFamily: 'Inter', fontSize: bodyFontSize) : hindiTextStyle)
                      .copyWith(decoration: TextDecoration.underline),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}