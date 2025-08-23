import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<dynamic> _contacts = [];
  bool _isLoading = true;
  String? _userPhone;
  String? expandedContactId;

  final String _serverUrl = 'https://340a2c6ff635.ngrok-free.app';
  late final Box _contactsBox;

  @override
  void initState() {
    super.initState();
    _contactsBox = Hive.box('emergency_contacts');
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() { _isLoading = true; });
    final prefs = await SharedPreferences.getInstance();
    _userPhone = prefs.getString('user_phone');
    if (_userPhone == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    try {
      final response = await http.get(Uri.parse('$_serverUrl/user/$_userPhone/contacts'));
      if (mounted && response.statusCode == 200) {
        final serverContacts = jsonDecode(response.body);
        setState(() {
          _contacts = serverContacts;
          _isLoading = false;
        });
        await _contactsBox.put('contacts', serverContacts);
      } else {
        _loadFromLocal();
      }
    } catch (e) {
       _loadFromLocal();
    }
  }

  void _loadFromLocal() {
    final localContacts = _contactsBox.get('contacts', defaultValue: []);
    if(mounted) {
      setState(() {
        _contacts = List<dynamic>.from(localContacts);
        _isLoading = false;
      });
      if (localContacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No contacts found. Please connect to the internet to sync.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Showing offline contacts. Connect to internet to refresh.')));
      }
    }
  }
  
  // UPDATED: This function is now more robust.
  Future<void> _pickAndSaveContact() async {
    try {
      // 1. Explicitly check permission status
      final status = await Permission.contacts.status;
      if (status.isDenied) {
        debugPrint("Contacts permission is denied. Requesting now...");
        if (await Permission.contacts.request().isGranted) {
          debugPrint("Contacts permission granted.");
        } else {
          debugPrint("Contacts permission was permanently denied by the user.");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacts permission is required to add an emergency contact.')));
          }
          return;
        }
      }
      
      if (await Permission.contacts.isGranted) {
        debugPrint("Permission is granted, attempting to open contact picker...");
        final Contact? contact = await FlutterContacts.openExternalPick();
        
        if (contact != null) {
          if (contact.phones.isNotEmpty) {
            final newName = contact.displayName;
            final newNumber = contact.phones.first.number;

            final isDuplicate = _contacts.any((c) => c['phone'] == newNumber);
            if (isDuplicate) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact already exists.')));
              return;
            }

            await http.post(
              Uri.parse('$_serverUrl/user/$_userPhone/contacts'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'name': newName, 'phone': newNumber}),
            );
            _loadContacts();
          } else {
            debugPrint("Selected contact has no phone number.");
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected contact does not have a phone number.')));
          }
        } else {
          debugPrint("Contact picking was cancelled by the user.");
        }
      }
    } catch (e) {
      debugPrint("An error occurred in _pickAndSaveContact: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')));
      }
    }
  }


  Future<void> _deleteContact(String contactId) async {
    try {
      final response = await http.delete(Uri.parse('$_serverUrl/user/$_userPhone/contacts/$contactId'));
      if (response.statusCode == 200) {
        _loadContacts();
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete contact: ${response.body}')));
        }
      }
    } catch (e) {
       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete. Check your internet connection.')));
        }
    }
  }
  
  void _showDeleteConfirmationDialog(String docId, String name, bool isHindi) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isHindi ? 'हटाने की पुष्टि करें' : 'Confirm Deletion'),
          content: Text('${isHindi ? 'क्या आप वाकई हटाना चाहते हैं' : 'Are you sure you want to delete'} "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteContact(docId);
              },
              child: Text(isHindi ? 'हटाएं' : 'Delete', style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, child) {
        final isHindi = languageNotifier.isHindi;
        return Scaffold(
          appBar: AppBar(title: Text(isHindi ? 'आपात संपर्क' : 'Emergency Contacts')),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _contacts.isEmpty
                  ? Center(
                      child: Text(isHindi ? 'कोई संपर्क नहीं जोड़ा गया' : 'No contacts added'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        final name = contact['name'] ?? 'No Name';
                        final phone = contact['phone'] ?? 'No Number';
                        final contactId = contact['_id'];
                        final isExpanded = expandedContactId == contactId;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                expandedContactId = isExpanded ? null : contactId;
                              });
                            },
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(Icons.contacts, color: Theme.of(context).textTheme.bodyLarge?.color),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0,
                                        duration: const Duration(milliseconds: 300),
                                        child: Icon(Icons.expand_more, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  height: isExpanded ? 60 : 0,
                                  width: double.infinity,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: isExpanded ? 1.0 : 0.0,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 12, 14),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              phone,
                                              style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', fontSize: 15, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _showDeleteConfirmationDialog(contactId, name, isHindi),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _pickAndSaveContact,
            backgroundColor: AppThemes.darkBlue,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              isHindi ? 'संपर्क जोड़ें' : 'Add Contact',
              style: TextStyle(
                fontFamily: isHindi ? 'Mukta' : 'Inter',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}