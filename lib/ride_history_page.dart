// lib/ride_history_page.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart'; // For theme colors

class RideHistoryPage extends StatelessWidget {
  final bool isHindi; // Keep for future language implementation

  const RideHistoryPage({super.key, this.isHindi = false}); // Added const constructor

  final List<Map<String, String>> dummyRides = const [ // Made dummy data const
    // Generate 10 dummy rides
    {'name': 'RAJU', 'phone': '+91 0000000000', 'date': '2024-07-20'},
    {'name': 'SEEMA', 'phone': '+91 1111111111', 'date': '2024-07-19'},
    {'name': 'AMIT', 'phone': '+91 2222222222', 'date': '2024-07-18'},
    {'name': 'PRIYA', 'phone': '+91 3333333333', 'date': '2024-07-17'},
    {'name': 'MOHAN', 'phone': '+91 4444444444', 'date': '2024-07-16'},
    {'name': 'NIDHI', 'phone': '+91 5555555555', 'date': '2024-07-15'},
    {'name': 'VIJAY', 'phone': '+91 6666666666', 'date': '2024-07-14'},
    {'name': 'POOJA', 'phone': '+91 7777777777', 'date': '2024-07-13'},
    {'name': 'ASHOK', 'phone': '+91 8888888888', 'date': '2024-07-12'},
    {'name': 'SWATI', 'phone': '+91 9999999999', 'date': '2024-07-11'},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double headerFixedPxHeight = 70.0; // Consistent header height

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Themed background
      body: SafeArea(
        child: Column(
          children: [
            // Top Flat Blue Header Bar (consistent with Profile, QR Scan pages)
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
                      icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                      onPressed: () { print('Profile Icon Pressed from Ride History'); },
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
                      icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                      onPressed: () { print('Settings Icon Pressed from Ride History'); },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Space below header

            // "Last 10 rides" Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft, // Align left as per screenshot
                child: Text(
                  isHindi ? 'पिछली 10 सवारी' : 'Last 10 rides',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith( // Themed text color
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // List of Ride Items
            Expanded(
              child: ListView.builder(
                itemCount: dummyRides.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, // Themed card background
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.1), // Themed shadow color
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.surface, // Themed avatar background
                            child: Icon(Icons.person, size: 32, color: Theme.of(context).textTheme.bodyLarge?.color), // Themed icon color
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dummyRides[index]['name']!,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith( // Themed text color
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dummyRides[index]['phone']!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith( // Themed text color
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color, // Ensure contrast in dark mode
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}