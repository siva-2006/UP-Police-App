// lib/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

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
  File? _imageFile;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadProfileDetails() async {
    setState(() { _isLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && userDoc.exists) {
          final data = userDoc.data()!;
          _nameController.text = data['name'] ?? '';
          _mobileNoController.text = data['phoneNumber'] ?? '';
          _aadhaarNoController.text = data['aadhaarNumber'] ?? '';
          _dobController.text = data['dateOfBirth'] ?? '';
          _profileImageUrl = data['profileImageUrl'];
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _pickAndCropImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: AppThemes.darkBlue,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
          hideBottomControls: true,
          statusBarColor: AppThemes.darkBlue, // ← fixes content overlap with status bar
          showCropGrid: true,
          cropFrameStrokeWidth: 2,
          cropGridStrokeWidth: 1,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imageFile = File(croppedFile.path);
      });
    }
  }




  Future<String?> _uploadProfilePicture(String userId) async {
    if (_imageFile == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_pictures').child('$userId.jpg');
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfileDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String? newImageUrl = await _uploadProfilePicture(user.uid);
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'name': _nameController.text.trim(),
            'aadhaarNumber': _aadhaarNoController.text.trim(),
            'dateOfBirth': _dobController.text.trim(),
            if (newImageUrl != null) 'profileImageUrl': newImageUrl,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
          }
          _profileImageUrl = newImageUrl ?? _profileImageUrl;
          _imageFile = null;
        }
      } catch (e) {
        // handle error
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isEditing = false;
          });
        }
      }
    }
  }

  void _discardChanges() {
    setState(() {
      _isEditing = false;
      _imageFile = null;
      _loadProfileDetails();
    });
  }

  Future<void> _showDiscardConfirmationDialog() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('Are you sure you want to discard your changes?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _discardChanges();
              },
              child: const Text('Discard')),
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
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfilePicture(),
                    const SizedBox(height: 40),
                    _buildTextFormField(
                      controller: _nameController,
                      label: 'Name',
                      enabled: _isEditing,
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
                      enabled: _isEditing,
                      validator: (v) => v!.isNotEmpty && v.length != 12 ? 'Enter a valid 12-digit number' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildTextFormField(
                      controller: _dobController,
                      label: 'Date of Birth',
                      readOnly: true,
                      enabled: _isEditing,
                      onTap: _isEditing ? () => _selectDate(context) : null,
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    const SizedBox(height: 50),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePicture() {
    final double radius = MediaQuery.of(context).size.width * 0.15;
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Theme.of(context).colorScheme.surface,
          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
          child: _imageFile == null && _profileImageUrl == null ? Icon(Icons.person, size: radius, color: Theme.of(context).textTheme.bodyMedium?.color) : null,
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickAndCropImage,
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: AppThemes.accentPink,
                child: Icon(Icons.edit, color: Colors.white, size: 22),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _showDiscardConfirmationDialog,
              child: const Text('Discard'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveProfileDetails,
              child: const Text('Save'),
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
          child: const Text('Edit Profile'),
        ),
      );
    }
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