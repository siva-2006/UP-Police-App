// lib/ride_history_page.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart';

class RideHistoryPage extends StatelessWidget {
  const RideHistoryPage({super.key});

  // Dummy data for demonstration
  final List<Map<String, String>> dummyRides = const [
    {'name': 'RAJU', 'phone': '+91 0000000000', 'date': '2024-07-20'},
    {'name': 'SEEMA', 'phone': '+91 1111111111', 'date': '2024-07-19'},
    {'name': 'AMIT', 'phone': '+91 2222222222', 'date': '2024-07-18'},
    {'name': 'PRIYA', 'phone': '+91 3333333333', 'date': '2024-07-17'},
    {'name': 'MOHAN', 'phone': '+91 4444444444', 'date': '2024-07-16'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ride History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: dummyRides.length,
        itemBuilder: (context, index) {
          final ride = dummyRides[index];
          final name = ride['name']!;
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(ride['phone']!),
              trailing: Text(ride['date']!),
            ),
          );
        },
      ),
    );
  }
}