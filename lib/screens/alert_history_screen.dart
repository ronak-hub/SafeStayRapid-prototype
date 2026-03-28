import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see history")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alert History"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .where('raisedBy', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No alerts raised yet",
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final alerts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final data = alerts[index].data() as Map<String, dynamic>;
              final type = data['type'] ?? 'UNKNOWN';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final timeStr = timestamp != null
                  ? "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} • ${timestamp.day}/${timestamp.month}/${timestamp.year}"
                  : 'Just now';
              final location = data['location'] ?? 'Not specified';
              final status = data['status'] ?? 'active';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: status == 'active' ? Colors.red : Colors.green,
                    size: 40,
                  ),
                  title: Text(
                    "$type Alert",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Time: $timeStr\nLocation: $location",
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Chip(
                    label: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: status == 'active' ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: status == 'active' ? Colors.red[50] : Colors.green[50],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}