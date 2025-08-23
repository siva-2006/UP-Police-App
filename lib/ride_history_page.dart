// lib/ride_history_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RideHistoryPage extends StatefulWidget {
  RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  List<dynamic> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRideHistory();
  }

  Future<void> _fetchRideHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userPhone = prefs.getString('user_phone');

    if (userPhone == null) {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      }
      return;
    }

    const String serverUrl = 'https://340a2c6ff635.ngrok-free.app';
    final String userApiUrl = '$serverUrl/user/$userPhone/rides';

    try {
      final response = await http.get(Uri.parse(userApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Sorts the rides by timestamp in descending order and takes the first 5
        data.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
        if (mounted) {
          setState(() {
            _rides = data.take(5).toList();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load ride history: ${response.statusCode}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error: Could not connect to user database.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty
              ? const Center(
                  child: Text(
                    'You have no ride history yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _rides.length,
                  itemBuilder: (context, index) {
                    final rideData = _rides[index] as Map<String, dynamic>;
                    final name = rideData['name'] ?? 'No Name';
                    final date = rideData['timestamp'] != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(rideData['timestamp']))
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
                ),
    );
  }
}