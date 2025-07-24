// lib/otp_verification_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:eclub_app/welcome_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:eclub_app/enter_details_screen.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
  final bool isHindi;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
    this.isHindi = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  late bool _isHindi;
  bool _isLoading = false;
  String? _otpErrorText;

  Timer? _timer;
  int _resendCooldown = 0;
  int _cooldownAttempts = 0;
  late int? _currentResendToken;

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
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
    final FirebaseAuth auth = FirebaseAuth.instance;
    await auth.verifyPhoneNumber(
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
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EnterDetailsScreen(phoneNumber: widget.phoneNumber, isHindi: _isHindi)));
          }
        }
      }
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }
  
  void _validateAndVerifyOtp() {
    if (_otpController.text.trim().length == 6) {
      setState(() { _otpErrorText = null; });
      _verifyOtp();
    } else {
      setState(() { _otpErrorText = _isHindi ? 'कृपया 6 अंकों का ओटीपी दर्ज करें' : 'Enter a valid 6-digit OTP'; });
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
    final screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = screenWidth * 0.055;
    final double bodyFontSize = screenWidth * 0.04;
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
                    child: Text('ASTRA', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 36)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('LOGIN/REGISTER', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: titleFontSize)),
              const SizedBox(height: 20),
              Image.asset('assets/images/image_6d3861.png', height: 120),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Text(
                  'Enter OTP sent to mobile number ending in ${getLastFourDigits(widget.phoneNumber)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: bodyFontSize),
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
                  style: TextStyle(letterSpacing: 4, fontSize: screenWidth * 0.05),
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
                child: Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateAndVerifyOtp,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('VERIFY'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: canResend ? _resendOtp : null,
                child: Text(
                  canResend ? 'Resend OTP' : 'Resend OTP in $_resendCooldown s',
                  style: TextStyle(fontSize: bodyFontSize, decoration: TextDecoration.underline),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Change phone number', style: TextStyle(fontSize: bodyFontSize, decoration: TextDecoration.underline)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}