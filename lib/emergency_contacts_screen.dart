// lib/emergency_contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart'; // Import main to access languageNotifier
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, child) {
        final isHindi = languageNotifier.isHindi;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(isHindi ? 'आपात संपर्क' : 'Emergency Contacts'),
          ),
          body: const ContactList(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _pickAndSaveContact(context),
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

  Future<void> _pickAndSaveContact(BuildContext context) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (await FlutterContacts.requestPermission()) {
      final existingContactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('emergencyContacts')
          .get();
      final existingNumbers = existingContactsSnapshot.docs
          .map((doc) => (doc.data()['phone'] as String).replaceAll(RegExp(r'[^0-9]'), ''))
          .toSet();

      final Contact? contact = await FlutterContacts.openExternalPick();

      if (contact != null && contact.phones.isNotEmpty) {
        final newNumber = contact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '');

        if (existingNumbers.contains(newNumber)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This contact is already in your emergency list.')),
            );
          }
          return;
        }

        _saveContactToFirestore(currentUser.uid, contact.displayName, contact.phones.first.number);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission is required.')),
        );
      }
    }
  }

  Future<void> _saveContactToFirestore(String userId, String name, String phone) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emergencyContacts')
          .add({'name': name, 'phone': phone});
    } catch (e) {
      // Handle error
    }
  }
}

class ContactList extends StatelessWidget {
  const ContactList({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Please log in."));
    }

    final isHindi = languageNotifier.isHindi;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('emergencyContacts')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isHindi ? 'कोई संपर्क नहीं जोड़ा गया है। कृपया एक आपातकालीन संपर्क जोड़ें।' : 'No contacts added. Please add an emergency contact.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: isHindi ? 'Mukta' : 'Inter', fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final contacts = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return ContactCard(
              contactData: contact.data() as Map<String, dynamic>,
              docId: contact.id,
              currentUser: currentUser,
            );
          },
        );
      },
    );
  }
}

class ContactCard extends StatefulWidget {
  final Map<String, dynamic> contactData;
  final String docId;
  final User? currentUser;

  const ContactCard({
    super.key,
    required this.contactData,
    required this.docId,
    required this.currentUser,
  });

  @override
  State<ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<ContactCard> {
  bool _isExpanded = false;

  Future<void> _deleteContact() async {
    if (widget.currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser!.uid)
          .collection('emergencyContacts')
          .doc(widget.docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact removed.')),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  void _showDeleteConfirmationDialog() {
    final isHindi = languageNotifier.isHindi;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isHindi ? 'हटाने की पुष्टि करें' : 'Confirm Deletion'),
          content: Text('${isHindi ? 'क्या आप वाकई हटाना चाहते हैं' : 'Are you sure you want to delete'} "${widget.contactData['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteContact();
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
    final isHindi = languageNotifier.isHindi;
    final name = widget.contactData['name'] ?? (isHindi ? 'कोई नाम नहीं' : 'No Name');
    final phone = widget.contactData['phone'] ?? (isHindi ? 'कोई नंबर नहीं' : 'No Number');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
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
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.expand_more, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isExpanded ? 60 : 0,
              width: double.infinity,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isExpanded ? 1.0 : 0.0,
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
                        onPressed: _showDeleteConfirmationDialog,
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
  }
}