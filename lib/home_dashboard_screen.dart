import 'dart:async';
import 'package:eclub_app/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:eclub_app/profile_screen.dart';
import 'package:eclub_app/emergency_contacts_screen.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart';
import 'package:eclub_app/ride_history_page.dart';
import 'package:eclub_app/more_settings_page.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eclub_app/scream_detection_service.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final ValueNotifier<String> _callPoliceStatusNotifier = ValueNotifier('');
  Timer? _callPoliceTimer;

  @override
  void dispose() {
    _callPoliceStatusNotifier.dispose();
    _callPoliceTimer?.cancel();
    super.dispose();
  }

  void _handleCallPolicePress() {
    notificationService.showCallPoliceConfirmationNotification(onCancel: () {
      _callPoliceStatusNotifier.value = "Cancelled by user";
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _callPoliceStatusNotifier.value = "";
      });
    });

    int countdown = 30;
    _callPoliceStatusNotifier.value = "Activating in $countdown...";
    _callPoliceTimer?.cancel();
    _callPoliceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown--;
      if (countdown <= 0) {
        timer.cancel();
        _callPoliceStatusNotifier.value = "Activated!";
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _callPoliceStatusNotifier.value = "";
        });
      } else if (_callPoliceStatusNotifier.value.contains("Cancelled")) {
        timer.cancel();
      } else {
        if (mounted) _callPoliceStatusNotifier.value = "Activating in $countdown...";
      }
    });
  }

  // UPDATED: This is the new, robust logout function
  Future<void> _logout() async {
    // 1. Stop any active services
    ScreamDetectionService().stop();

    // 2. Clear all local session data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears all SharedPreferences data

    // 3. Clear all cached data from Hive boxes
    await Hive.box('emergency_contacts').clear();
    await Hive.box('user_profile').clear();
    
    // 4. Navigate to the login screen, removing all previous screens from history
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
      child: SizedBox(
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

  Widget _buildStatusBox(String status, Color color, bool isHindi) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isHindi ? "मैनुअल अलर्ट:" : "MANUAL ALERT:",
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
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
                _buildMenuButton(isHindi ? 'सवारी का इतिहास' : 'Rides Taken', Icons.history, () => Navigator.push(context, MaterialPageRoute(builder: (context) => RideHistoryPage()))),
                _buildMenuButton(isHindi ? 'अधिक सेटिंग्स' : 'More Settings', Icons.more_horiz, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MoreSettingsPage()))),
                _buildMenuButton(isHindi ? 'भाषा बदलें (English)' : 'Change Language (हिन्दी)', Icons.language, () => languageNotifier.toggleLanguage()),
                const Spacer(),
                _buildMenuButton(isHindi ? 'लॉग आउट' : 'Logout', Icons.logout, () => _showLogoutConfirmationDialog(isHindi)),
                
                ValueListenableBuilder<String>(
                  valueListenable: _callPoliceStatusNotifier,
                  builder: (context, status, child) {
                    if (status.isEmpty) return const SizedBox.shrink();
                    
                    Color statusColor = status.contains("Cancelled") ? Colors.green : Colors.orangeAccent;
                    
                    return _buildStatusBox(status, statusColor, isHindi);
                  },
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: ElevatedButton(
                       onPressed: _handleCallPolicePress,
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