// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/otp_verification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
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
    setState(() => _isLoading = true);
    final String phoneNumber = '+91${_phoneController.text.trim()}';
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) setState(() => _isLoading = false);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send OTP: ${e.message}")),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: _phoneController.text.trim(),
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  void _validateAndSendOtp(bool isHindi) {
    if (_phoneController.text.trim().length == 10) {
      setState(() => _phoneErrorText = null);
      _savePhoneNumber(_phoneController.text.trim());
      _sendOtp();
    } else {
      setState(() {
        _phoneErrorText = isHindi
            ? 'कृपया एक मान्य 10-अंकीय फ़ोन नंबर दर्ज करें'
            : 'Enter valid 10-digit number';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, child) {
        final isHindi = languageNotifier.isHindi;
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

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
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 36, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    isHindi ? 'लॉगिन/रजिस्टर' : 'LOGIN/REGISTER',
                    style: TextStyle(
                      fontFamily: isHindi ? 'Mukta' : 'Inter',
                      color: AppThemes.darkBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Image.asset('assets/images/image_6d3861.png', height: screenHeight * 0.19),
                  SizedBox(height: screenHeight * 0.05),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: InputDecoration(
                        counterText: "",
                        labelText: isHindi ? 'मोबाइल नंबर' : 'Mobile Number',
                        errorText: _phoneErrorText,
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _validateAndSendOtp(isHindi),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.tealGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isHindi ? 'ओटीपी भेजें' : 'SEND OTP',
                                style: TextStyle(
                                    fontFamily: isHindi ? 'Mukta' : 'Inter',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.07),
                  TextButton(
                    onPressed: () => languageNotifier.toggleLanguage(),
                    child: Text(
                      isHindi ? 'Change Language' : 'भाषा बदलें',
                      style: TextStyle(
                        fontFamily: isHindi ? 'Inter' : 'Mukta',
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}