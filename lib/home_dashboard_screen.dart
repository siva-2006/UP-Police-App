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

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {

  Future<void> _logout() async {
    // For now, just navigate to the login screen
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _showLogoutConfirmationDialog(bool isHindi) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isHindi ? 'लॉगआउट की पुष्टि करें' : 'Confirm Logout'),
          content: Text(isHindi ? 'क्या आप वाकई लॉग आउट करना चाहते हैं?' : 'Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
              onPressed: () => Navigator.of(context).pop(),
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
        height: 55.0,
        child: MaterialButton(
          onPressed: onPressed,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 16),
              Text(
                text,
                style: TextStyle(
                  fontFamily: languageNotifier.isHindi ? 'Mukta' : 'Inter',
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
            title: Text(isHindi ? 'जागृति सुरक्षा' : 'Jagriti Suraksha'),
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
                _buildMenuButton(isHindi ? 'ड्राइवर का विवरण' : 'Driver Details', Icons.person_search, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverDetailsScreen(driverDetails: {})))),
                _buildMenuButton(isHindi ? 'सवारी का इतिहास' : 'Rides Taken', Icons.history, () => Navigator.push(context, MaterialPageRoute(builder: (context) => RideHistoryPage()))),
                _buildMenuButton(isHindi ? 'अधिक सेटिंग्स' : 'More Settings', Icons.more_horiz, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MoreSettingsPage()))),
                _buildMenuButton(isHindi ? 'भाषा बदलें (English)' : 'Change Language (हिन्दी)', Icons.language, () => languageNotifier.toggleLanguage()),
                const Spacer(),
                _buildMenuButton(isHindi ? 'लॉग आउट' : 'Logout', Icons.logout, () => _showLogoutConfirmationDialog(isHindi)),
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