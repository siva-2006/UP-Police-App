// lib/otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/enter_details_screen.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? _otpErrorText;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyAndProceed(bool isHindi) {
    if (_otpController.text.trim().length == 6) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EnterDetailsScreen(phoneNumber: widget.phoneNumber),
        ),
      );
    } else {
      setState(() {
        _otpErrorText = isHindi ? 'कृपया 6 अंकों का ओटीपी दर्ज करें' : 'Enter a valid 6-digit OTP';
      });
    }
  }
  
  String getLastFourDigits(String phone) {
    if (phone.length >= 4) return phone.substring(phone.length - 4);
    return "xxxx";
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, child) {
        final isHindi = languageNotifier.isHindi;
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
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
                        onPressed: () => _verifyAndProceed(isHindi),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.tealGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: Text(
                          isHindi ? 'सत्यापित करें' : 'VERIFY',
                           style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}