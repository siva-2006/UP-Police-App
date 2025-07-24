// lib/enter_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eclub_app/welcome_home_screen.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnterDetailsScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isHindi;

  const EnterDetailsScreen({
    super.key,
    required this.phoneNumber,
    this.isHindi = false,
  });

  @override
  State<EnterDetailsScreen> createState() => _EnterDetailsScreenState();
}

class _EnterDetailsScreenState extends State<EnterDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _aadhaarNoController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;
  late bool _isHindi;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isHindi = widget.isHindi;
    _mobileNoController.text = widget.phoneNumber;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileNoController.dispose();
    _aadhaarNoController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _saveUserDetailsToFirestore() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'phoneNumber': widget.phoneNumber,
            'aadhaarNumber': _aadhaarNoController.text.trim(),
            'dateOfBirth': _dobController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeHomeScreen()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        setState(() { _isLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save details: ${e.toString()}")),
          );
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth * 0.055;

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
                const SizedBox(height: 30),
                Text(
                  'ENTER DETAILS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: titleFontSize),
                ),
                const SizedBox(height: 30),
                _buildTextFormField(
                  controller: _nameController,
                  label: 'Name',
                  validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 24),
                _buildTextFormField(
                  controller: _mobileNoController,
                  label: 'Mobile Number',
                  enabled: false,
                ),
                const SizedBox(height: 24),
                _buildTextFormField(
                  controller: _aadhaarNoController,
                  label: 'Aadhaar Number',
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  validator: (v) => v!.isNotEmpty && v.length != 12 ? 'Enter a valid 12-digit number' : null,
                ),
                const SizedBox(height: 24),
                _buildTextFormField(
                  controller: _dobController,
                  label: 'Date of Birth',
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveUserDetailsToFirestore,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT DETAILS'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    bool readOnly = false,
    int? maxLength,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
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