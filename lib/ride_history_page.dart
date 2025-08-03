// lib/ride_history_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:eclub_app/app_themes.dart';
import 'package:eclub_app/main.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  List<dynamic> _rides = [];
  bool _isLoading = true;
  
  final String _serverUrl = 'http://192.168.137.1:3000';

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() { _isLoading = true; });
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('user_phone');
    if (userPhone == null) {
       if (mounted) setState(() { _isLoading = false; });
      return;
    }

    try {
      final response = await http.get(Uri.parse('$_serverUrl/user/$userPhone/rides'));
      if (mounted && response.statusCode == 200) {
        setState(() {
          _rides = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
     return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, child) {
        final isHindi = languageNotifier.isHindi;
        return Scaffold(
          appBar: AppBar(title: Text(isHindi ? 'सवारी का इतिहास' : 'Ride History')),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _rides.isEmpty
                  ? Center(child: Text(isHindi ? 'कोई सवारी इतिहास नहीं मिला' : 'No ride history found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _rides.length,
                      itemBuilder: (context, index) {
                        final ride = _rides[index];
                        final name = ride['name'] ?? 'No Name';
                        final timestamp = ride['timestamp'] != null ? DateTime.parse(ride['timestamp']).toLocal() : null;
                        final date = timestamp != null ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp) : 'No Date';

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
                            subtitle: Text(ride['vehicleNumber'] ?? 'N/A'),
                            trailing: Text(date, style: Theme.of(context).textTheme.bodySmall),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}