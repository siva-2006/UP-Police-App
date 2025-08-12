// lib/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:eclub_app/enter_details_screen.dart';
import 'package:eclub_app/welcome_home_screen.dart';
import 'package:eclub_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eclub_app/app_themes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _userExists = false;
  bool _isLoading = false;
  String? _phoneErrorText;
  
  final String _serverUrl = 'http://192.168.137.1:3000';

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkUserExists() async {
    if (_phoneController.text.trim().length != 10) {
      if (mounted) setState(() => _userExists = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/user/exists/${_phoneController.text.trim()}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _userExists = data['exists']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot connect to server.")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleProceed() async {
    setState(() => _isLoading = true);
    final isHindi = languageNotifier.isHindi;

    if (_userExists) {
      try {
        final response = await http.post(
          Uri.parse('$_serverUrl/user/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'phoneNumber': _phoneController.text.trim(),
            'pin': _pinController.text.trim(),
          }),
        );
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(response.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_phone', data['user']['phoneNumber']);
          await prefs.setString('user_name', data['user']['name']);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WelcomeHomeScreen()));
        } else if (mounted) {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Invalid PIN')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login failed. Check server connection.")));
      }
    } else {
      if (_phoneController.text.trim().length == 10) {
         Navigator.push(context, MaterialPageRoute(builder: (context) => EnterDetailsScreen(phoneNumber: _phoneController.text.trim())));
      } else {
        setState(() {
          _phoneErrorText = isHindi ? 'कृपया एक मान्य 10-अंकीय फ़ोन नंबर दर्ज करें' : 'Enter valid 10-digit number';
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
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
                      child: Text('ASTRA', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 36, color: Colors.white)),
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
                      onChanged: (value) => _checkUserExists(),
                    ),
                  ),
                  if (_userExists)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 16),
                      child: TextField(
                        controller: _pinController,
                        obscureText: true,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          counterText: "",
                          labelText: isHindi ? '4-अंकीय पिन' : '4-Digit PIN',
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
                        onPressed: _isLoading ? null : _handleProceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemes.tealGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _userExists ? (isHindi ? 'लॉगिन करें' : 'LOGIN') : (isHindi ? 'आगे बढ़ें' : 'PROCEED'),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}