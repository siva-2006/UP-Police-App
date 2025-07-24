// lib/driver_details_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart'; // For theme colors

class DriverDetailsScreen extends StatelessWidget { // Keep as StatelessWidget for now
  const DriverDetailsScreen({super.key});

  // Helper widget for the pill-shaped buttons
  Widget _buildPillButton(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20), // Added horizontal padding for spacing
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16), // Increased vertical padding for taller button
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, // Themed background for button
          borderRadius: BorderRadius.circular(30), // Pill shape
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith( // Themed text color
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 18, // Slightly larger font size
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    const double headerFixedPxHeight = 70.0; // Height of the flat blue header
    const double profileCircleDiameter = 120.0; // Diameter of the large profile circle
    const double checkCircleDiameter = 32.0; // Diameter of the small check circle

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Themed background
      body: SafeArea(
        child: Stack( // Use Stack for the floating 'X' button
          children: [
            Column(
              children: [
                // Top Flat Blue Header Bar
                Container(
                  height: headerFixedPxHeight,
                  width: double.infinity,
                  color: AppThemes.darkBlue, // Consistent dark blue
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_outline, color: Colors.white, size: 28), // White icons
                          onPressed: () { print('Profile Icon Pressed from Driver Details'); },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/image_6d3861.png', // Correct asset path
                              height: headerFixedPxHeight * 0.6,
                              width: headerFixedPxHeight * 0.6 * (11/7),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ASTRA',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white, size: 28), // White icons
                          onPressed: () { print('Settings Icon Pressed from Driver Details'); },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Grey Body (Expanded to fill remaining space)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor, // Themed background for this section
                      borderRadius: const BorderRadius.only( // Rounded top corners
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30), // Space from the top curved edge

                        // Profile Circle with Check
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: profileCircleDiameter / 2,
                              backgroundColor: Theme.of(context).colorScheme.surface, // Themed surface color
                              child: Icon(Icons.person, size: profileCircleDiameter * 0.5, color: Theme.of(context).textTheme.bodyMedium?.color), // Themed icon color
                            ),
                            CircleAvatar(
                              radius: checkCircleDiameter / 2,
                              backgroundColor: Colors.green, // Keep green as per image
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30), // Space below profile circle

                        // Pill Buttons
                        _buildPillButton(context, 'Name'),
                        _buildPillButton(context, 'Vehicle Number'),
                        _buildPillButton(context, 'Phone'),
                        _buildPillButton(context, 'Last Checked'),
                        _buildPillButton(context, 'Route'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Close Button ('X' button)
            Positioned(
              top: headerFixedPxHeight + 10, // Position below header + some gap
              right: screenWidth * 0.05, // Aligned with right edge of content
              child: IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge?.color, size: 30), // Themed icon color
                onPressed: () {
                  Navigator.pop(context); // Go back to previous screen
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}