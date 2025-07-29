// lib/home_dashboard_screen.dart
import 'package:eclub_app/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:eclub_app/profile_screen.dart';
import 'package:eclub_app/emergency_contacts_screen.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart';
import 'package:eclub_app/qr_scan_page.dart';
import 'package:eclub_app/driver_details_screen.dart';
import 'package:eclub_app/ride_history_page.dart';
import 'package:eclub_app/more_settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {
    final isHindi = languageNotifier.isHindi;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isHindi ? 'लॉगआउट की पुष्टि करें' : 'Confirm Logout'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(isHindi ? 'क्या आप वाकई लॉग आउट करना चाहते हैं?' : 'Are you sure you want to log out?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(isHindi ? 'लॉग आउट' : 'Logout', style: const TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuButton(String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20.0),
      child: Container(
        width: double.infinity,
        height: 55.0,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade300 : Colors.grey.shade700,
            width: 1.5,
          ),
        ),
        child: MaterialButton(
          onPressed: onPressed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color),
              const SizedBox(width: 16),
              Text(
                text,
                style: TextStyle(
                  fontFamily: languageNotifier.isHindi ? 'Mukta' : 'Inter',
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, child) {
        final isHindi = languageNotifier.isHindi;
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          appBar: AppBar(
            title: Text(isHindi ? 'अस्त्र' : 'ASTRA'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline, size: 30),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildMenuButton(isHindi ? 'लाइट/डार्क मोड' : 'Light/Dark Mode', Icons.brightness_6, () => themeNotifier.toggleTheme()),
                _buildMenuButton(isHindi ? 'आपात संपर्क' : 'Emergency Contacts', Icons.contact_emergency, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()))),
                // --- FIX APPLIED HERE ---
                _buildMenuButton(
                  isHindi ? 'ड्राइवर का विवरण' : 'Driver Details', 
                  Icons.person_search, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverDetailsScreen(driverDetails: {})))
                ),
                _buildMenuButton(isHindi ? 'सवारी का इतिहास' : 'Rides Taken', Icons.history, () => Navigator.push(context, MaterialPageRoute(builder: (context) => RideHistoryPage()))),
                _buildMenuButton(isHindi ? 'अधिक सेटिंग्स' : 'More Settings', Icons.more_horiz, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MoreSettingsPage()))),
                _buildMenuButton(isHindi ? 'भाषा बदलें (English)' : 'Change Language (हिन्दी)', Icons.language, () => languageNotifier.toggleLanguage()),
                const Spacer(),
                _buildMenuButton(isHindi ? 'लॉग आउट' : 'Logout', Icons.logout, _showLogoutConfirmationDialog),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: ElevatedButton(
                       onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemes.emergencyRed,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(
                        isHindi ? 'पुलिस को बुलाओ' : 'CALL POLICE',
                        style: TextStyle(
                          fontFamily: isHindi ? 'Mukta' : 'Inter',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}