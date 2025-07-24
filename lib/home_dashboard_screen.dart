// lib/home_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/profile_screen.dart';
import 'package:eclub_app/emergency_contacts_screen.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart'; // To access themeNotifier
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
  // Reusable Widget for the menu buttons
  Widget _buildMenuButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 20.0),
      child: Container(
        width: double.infinity,
        height: 50.0,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade300 : Colors.grey.shade700,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: MaterialButton(
          onPressed: onPressed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: EdgeInsets.zero,
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // --- REPLACED CONTAINER WITH APPBAR ---
      appBar: AppBar(
        backgroundColor: AppThemes.darkBlue,
        elevation: 0,
        title: Text(
          'ASTRA',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Ensures back button is white
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
            // The custom header container has been removed.

            // --- Menu Buttons ---
            const SizedBox(height: 30),
            _buildMenuButton('Light/Dark Mode', () {
              themeNotifier.toggleTheme();
            }),
            _buildMenuButton('Emergency Contacts', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()));
            }),
            _buildMenuButton('Driver Details', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverDetailsScreen()));
            }),
            _buildMenuButton('Rides Taken', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RideHistoryPage()));
            }),
            _buildMenuButton('More Settings', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MoreSettingsPage()));
            }),

            const Spacer(),

            // --- CALL POLICE Button ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 20),
              child: Container(
                width: double.infinity,
                height: 65,
                decoration: BoxDecoration(
                  color: AppThemes.emergencyRed,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemes.emergencyRed.withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: MaterialButton(
                  onPressed: () {
                    print('CALL POLICE Pressed!');
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: const Text(
                    'CALL POLICE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // --- Bottom Action Icons ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner, size: 40, color: Theme.of(context).iconTheme.color),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScanPage()));
                    },
                  ),
                   IconButton(
                    icon: Icon(Icons.camera_alt, size: 40, color: Theme.of(context).iconTheme.color),
                    onPressed: () {
                      // You can also navigate to QrScanPage or a dedicated camera page
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}