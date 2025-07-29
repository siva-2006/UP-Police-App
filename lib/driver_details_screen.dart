// lib/driver_details_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart';

class DriverDetailsScreen extends StatelessWidget {
  const DriverDetailsScreen({super.key});

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Driver Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ramesh Kumar', // Example Name
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'VERIFIED',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            _buildDetailRow(context, Icons.credit_card, 'Vehicle Number', 'UP 32 AB 1234'),
            _buildDetailRow(context, Icons.phone, 'Phone Number', '+91 9876543210'),
            _buildDetailRow(context, Icons.route, 'Route', 'Kanpur to Lucknow'),
            _buildDetailRow(context, Icons.schedule, 'Last Checked', '25 Jul 2025'),
          ],
        ),
      ),
    );
  }
}