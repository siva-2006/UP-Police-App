// lib/driver_details_screen.dart
import 'package:flutter/material.dart';
import 'package:eclub_app/app_themes.dart';

class DriverDetailsScreen extends StatelessWidget {
  final Map<String, String> driverDetails;

  const DriverDetailsScreen({super.key, required this.driverDetails});

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
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
        backgroundColor: AppThemes.darkBlue,
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
            Text(
              driverDetails['name'] ?? 'Unknown Driver',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Divider(),
            _buildDetailRow(context, Icons.directions_car, 'Vehicle Number', driverDetails['vehicleNumber'] ?? 'N/A'),
            _buildDetailRow(context, Icons.phone, 'Phone Number', driverDetails['phone'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }
}