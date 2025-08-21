// lib/enter_details_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:eclub_app/welcome_home_screen.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class EnterDetailsScreen extends StatefulWidget {
  final String phoneNumber;
  const EnterDetailsScreen({super.key, required this.phoneNumber});

  @override
  State<EnterDetailsScreen> createState() => _EnterDetailsScreenState();
}

class _EnterDetailsScreenState extends State<EnterDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  bool _isLoading = false;

  final String _serverUrl = 'http://192.168.137.1:3000';

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _aadhaarController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        final response = await http.post(
          Uri.parse('$_serverUrl/user/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'phoneNumber': widget.phoneNumber,
            'pin': _pinController.text.trim(),
            'name': _nameController.text.trim(),
            'aadhaarNumber': _aadhaarController.text.trim(),
            'dateOfBirth': _dobController.text.trim(),
          }),
        );

        if (response.statusCode == 201 && mounted) {
          final data = jsonDecode(response.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_phone', data['user']['phoneNumber']);
          await prefs.setString('user_name', data['user']['name']);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeHomeScreen()),
            (route) => false,
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: ${response.body}')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: ${e.toString()}')));
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, child) {
        final isHindi = languageNotifier.isHindi;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Hero(
                      tag: 'astra_header',
                      child: Container(
                        height: 120,
                        width: MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
                          color: AppThemes.darkBlue,
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
                        ),
                        child: Center(
                          child: Text(isHindi ? 'जागृति सुरक्षा' : 'Jagriti Suraksha', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 26, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      isHindi ? 'विवरण दर्ज करें' : 'ENTER DETAILS',
                      style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', color: AppThemes.darkBlue, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    _buildTextFormField(
                      context: context,
                      controller: _nameController,
                      label: isHindi ? 'नाम' : 'Name',
                      validator: (v) => v!.isEmpty ? (isHindi ? 'कृपया अपना नाम दर्ज करें' : 'Please enter your name') : null,
                    ),
                    const SizedBox(height: 24),
                     _buildTextFormField(
                      context: context,
                      controller: _pinController,
                      label: isHindi ? '4-अंकीय पिन सेट करें' : 'Set 4-Digit PIN',
                      isPassword: true,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.length != 4 ? (isHindi ? 'पिन 4 अंकों का होना चाहिए' : 'PIN must be 4 digits') : null,
                    ),
                    const SizedBox(height: 24),
                    _buildTextFormField(
                      context: context,
                      controller: _aadhaarController,
                      label: isHindi ? 'आधार नंबर' : 'Aadhaar Number',
                      keyboardType: TextInputType.number,
                      maxLength: 12
                    ),
                     const SizedBox(height: 24),
                    _buildTextFormField(
                      context: context,
                      controller: _dobController,
                      label: isHindi ? 'जन्म तिथि' : 'Date of Birth',
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      suffixIcon: const Icon(Icons.calendar_today)
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _registerUser,
                           style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemes.tealGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isHindi ? 'रजिस्टर करें' : 'REGISTER', style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextFormField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    bool readOnly = false,
    int? maxLength,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        enabled: enabled,
        maxLength: maxLength,
        keyboardType: keyboardType,
        onTap: onTap,
        validator: validator,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          counterText: "",
          filled: !enabled,
          fillColor: Theme.of(context).colorScheme.surface,
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}