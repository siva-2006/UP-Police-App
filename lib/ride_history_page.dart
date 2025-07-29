// lib/ride_history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RideHistoryPage extends StatelessWidget {
  RideHistoryPage({super.key});

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _getRidesStream() {
    if (_currentUser == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .collection('rides')
        .orderBy('timestamp', descending: true) // Show newest rides first
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getRidesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have no ride history yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final rides = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final rideData = rides[index].data() as Map<String, dynamic>;
              final name = rideData['name'] ?? 'No Name';
              final timestamp = rideData['timestamp'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                  : 'No Date';

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
                  subtitle: Text(rideData['vehicleNumber'] ?? 'No Vehicle Number'),
                  trailing: Text(date, style: Theme.of(context).textTheme.bodySmall),
                ),
              );
            },
          );
        },
      ),
    );
  }
}