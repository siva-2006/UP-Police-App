// lib/more_settings_page.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart'; // For theme colors

class MoreSettingsPage extends StatefulWidget {
  const MoreSettingsPage({super.key});

  @override
  State<MoreSettingsPage> createState() => _MoreSettingsPageState();
}

class _MoreSettingsPageState extends State<MoreSettingsPage> {
  bool sosEnabled = false;
  bool shakeToShareEnabled = false;
  bool screamDetectionEnabled = false;
  TextEditingController frequencyController = TextEditingController(text: "5");

  @override
  void dispose() {
    frequencyController.dispose();
    super.dispose();
  }

  // Helper for setting tiles (simplified, no language logic)
  Widget _buildSettingTile({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Themed background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue.shade700,
            inactiveTrackColor: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  // Helper for frequency tile (simplified, no language logic)
  Widget _buildFrequencyTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Themed background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sending freq.', // Hardcoded English
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
          ),
          SizedBox(
            width: 60,
            child: TextField(
              controller: frequencyController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double headerFixedPxHeight = 70.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Flat Blue Header Bar (consistent with other pages)
            Container(
              height: headerFixedPxHeight,
              width: double.infinity,
              color: AppThemes.darkBlue,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                      onPressed: () { print('Profile Icon Pressed from Settings'); },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/image_6d3861.png',
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
                      icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                      onPressed: () { print('Settings Icon Pressed from Settings'); },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Main content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    _buildSettingTile(
                      context: context,
                      label: 'SOS button', // Hardcoded English
                      value: sosEnabled,
                      onChanged: (val) { setState(() { sosEnabled = val; }); },
                    ),

                    _buildSettingTile(
                      context: context,
                      label: 'Shake to share', // Hardcoded English
                      value: shakeToShareEnabled,
                      onChanged: (val) { setState(() { shakeToShareEnabled = val; }); },
                    ),

                    _buildSettingTile(
                      context: context,
                      label: 'Scream detection', // Hardcoded English
                      value: screamDetectionEnabled,
                      onChanged: (val) { setState(() { screamDetectionEnabled = val; }); },
                    ),

                    _buildFrequencyTile(context),

                    const Spacer(), // Pushes content up

                    // Removed language buttons
                    // const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}