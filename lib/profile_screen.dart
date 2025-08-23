import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart'; // Import Hive

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _aadhaarNoController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;
  String? _userPhone;
  
  final String _serverUrl = 'https://340a2c6ff635.ngrok-free.app';
  late final Box _profileBox;

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box('user_profile');
    _loadProfileDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileNoController.dispose();
    _aadhaarNoController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // UPDATED: This function now includes an offline fallback
  Future<void> _loadProfileDetails() async {
    setState(() { _isLoading = true; });
    final prefs = await SharedPreferences.getInstance();
    _userPhone = prefs.getString('user_phone');
    if (_userPhone == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Try to fetch the latest data from the server
      final response = await http.get(Uri.parse('$_serverUrl/user/profile/$_userPhone'));
      if (mounted && response.statusCode == 200) {
        final serverData = jsonDecode(response.body);
        _updateTextFields(serverData);
        // Save the latest data to the local database
        await _profileBox.put('profile', serverData);
      } else {
        // If the server fails, load from the local database
        _loadFromLocal();
      }
    } catch (e) {
      // If there's a network error, load from the local database
      _loadFromLocal();
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // NEW: This function loads data from the Hive box
  void _loadFromLocal() {
    final localData = _profileBox.get('profile');
    if (mounted && localData != null) {
      _updateTextFields(Map<String, dynamic>.from(localData));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Showing offline profile. Connect to internet to refresh.')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load profile. Please connect to the internet.')));
    }
  }
  
  // NEW: Helper function to avoid code duplication
  void _updateTextFields(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _mobileNoController.text = data['phoneNumber'] ?? '';
    _aadhaarNoController.text = data['aadhaarNumber'] ?? '';
    _dobController.text = data['dateOfBirth'] ?? '';
  }

  Future<void> _saveProfileDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        final body = {
          'name': _nameController.text.trim(),
          'aadhaarNumber': _aadhaarNoController.text.trim(),
          'dateOfBirth': _dobController.text.trim(),
        };

        await http.put(
          Uri.parse('$_serverUrl/user/profile/$_userPhone'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
          // Also save the updated details to the local cache
          final updatedProfileData = _profileBox.get('profile') ?? {};
          updatedProfileData.addAll(body);
          await _profileBox.put('profile', updatedProfileData);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save. Check your internet connection.')));
      } finally {
        if (mounted) setState(() { _isLoading = false; _isEditing = false; });
      }
    }
  }
  
  void _discardChanges() {
    setState(() {
      _isEditing = false;
      // Reload the data to discard any changes
      _loadProfileDetails();
    });
  }

  Future<void> _showDiscardConfirmationDialog(bool isHindi) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(isHindi ? 'बदलाव हटाएं?' : 'Discard Changes?'),
        content: Text(isHindi ? 'क्या आप वाकई अपने बदलावों को हटाना चाहते हैं?' : 'Are you sure you want to discard your changes?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(isHindi ? 'रद्द करें' : 'Cancel')),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _discardChanges();
              },
              child: Text(isHindi ? 'हटाएं' : 'Discard')),
        ],
      ),
    );
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
          appBar: AppBar(title: Text(isHindi ? 'प्रोफ़ाइल' : 'Profile')),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, size: 80, color: Colors.white),
                        ),
                        const SizedBox(height: 40),
                        _buildTextFormField(
                          context: context,
                          controller: _nameController,
                          label: isHindi ? 'नाम' : 'Name',
                          enabled: _isEditing,
                          validator: (v) => v!.isEmpty ? (isHindi ? 'कृपया अपना नाम दर्ज करें' : 'Please enter your name') : null,
                        ),
                        const SizedBox(height: 24),
                        _buildTextFormField(
                          context: context,
                          controller: _mobileNoController,
                          label: isHindi ? 'मोबाइल नंबर' : 'Mobile Number',
                          enabled: false,
                        ),
                        const SizedBox(height: 24),
                        _buildTextFormField(
                          context: context,
                          controller: _aadhaarNoController,
                          label: isHindi ? 'आधार नंबर' : 'Aadhaar Number',
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          enabled: _isEditing,
                           validator: (v) => v!.isNotEmpty && v.length != 12 ? (isHindi ? 'मान्य 12-अंकीय नंबर दर्ज करें' : 'Enter a valid 12-digit number') : null,
                        ),
                        const SizedBox(height: 24),
                        _buildTextFormField(
                          context: context,
                          controller: _dobController,
                          label: isHindi ? 'जन्म तिथि' : 'Date of Birth',
                          readOnly: true,
                          enabled: _isEditing,
                          onTap: _isEditing ? () => _selectDate(context) : null,
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        const SizedBox(height: 50),
                        _buildActionButtons(isHindi),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildActionButtons(bool isHindi) {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showDiscardConfirmationDialog(isHindi),
              child: Text(isHindi ? 'हटाएं' : 'Discard'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveProfileDetails,
              child: Text(isHindi ? 'सहेजें' : 'Save'),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => setState(() { _isEditing = true; }),
          child: Text(isHindi ? 'प्रोफ़ाइल संपादित करें' : 'Edit Profile'),
        ),
      );
    }
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
  }) {
    return TextFormField(
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
    );
  }
}