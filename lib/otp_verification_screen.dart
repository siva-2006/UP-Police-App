// lib/otp_verification_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:eclub_app/welcome_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:eclub_app/enter_details_screen.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _otpErrorText;

  Timer? _timer;
  int _resendCooldown = 0;
  int _cooldownAttempts = 0;
  late int? _currentResendToken;

  @override
  void initState() {
    super.initState();
    _currentResendToken = widget.resendToken;
    startCooldownTimer();
  }

  void startCooldownTimer() {
    _resendCooldown = 30 * (pow(2, _cooldownAttempts).toInt());
    _cooldownAttempts++;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _resendOtp() async {
    startCooldownTimer();
    final String phoneNumber = '+91${widget.phoneNumber}';
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _currentResendToken,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {},
      codeSent: (String verificationId, int? resendToken) {
        _currentResendToken = resendToken;
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  String getLastFourDigits(String phone) {
    if (phone.length >= 4) return phone.substring(phone.length - 4);
    return "xxxx";
  }

  Future<void> _verifyOtp() async {
    setState(() { _isLoading = true; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
        if (mounted) {
          if (userDoc.exists) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const WelcomeHomeScreen()), (route) => false);
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EnterDetailsScreen(phoneNumber: widget.phoneNumber)));
          }
        }
      }
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  void _validateAndVerifyOtp(bool isHindi) {
    if (_otpController.text.trim().length == 6) {
      setState(() { _otpErrorText = null; });
      _verifyOtp();
    } else {
      setState(() { _otpErrorText = isHindi ? 'कृपया 6 अंकों का ओटीपी दर्ज करें' : 'Enter a valid 6-digit OTP'; });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, child) {
        final isHindi = languageNotifier.isHindi;
        final screenWidth = MediaQuery.of(context).size.width;
        final bool canResend = _resendCooldown == 0;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
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
                        child: Text('ASTRA', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 36, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isHindi ? 'लॉगिन/रजिस्टर' : 'LOGIN/REGISTER',
                    style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', color: AppThemes.darkBlue, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Image.asset('assets/images/image_6d3861.png', height: 120),
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: Text(
                      isHindi ? '${getLastFourDigits(widget.phoneNumber)} पर समाप्त होने वाले नंबर पर भेजा गया ओटीपी दर्ज करें' : 'Enter OTP sent to number ending in ${getLastFourDigits(widget.phoneNumber)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(letterSpacing: 4, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: "",
                        labelText: 'OTP',
                        errorText: _otpErrorText,
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _validateAndVerifyOtp(isHindi),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.tealGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(
                          isHindi ? 'सत्यापित करें' : 'VERIFY',
                           style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: canResend ? _resendOtp : null,
                    child: Text(
                      canResend ? (isHindi ? 'ओटीपी फिर से भेजें' : 'Resend OTP') : (isHindi ? '$_resendCooldown सेकंड में फिर से भेजें' : 'Resend OTP in $_resendCooldown s'),
                      style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', fontSize: 15, decoration: TextDecoration.underline),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isHindi ? 'फ़ोन नंबर बदलें' : 'Change phone number',
                      style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', fontSize: 15, decoration: TextDecoration.underline),
                    ),
                  ),
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}