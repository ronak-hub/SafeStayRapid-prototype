import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'alert_confirmation_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Dashboard - All Alerts"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text("No alerts yet.\nAll clear!", 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 18)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              // Safest way to handle Firestore data on web
              final rawData = doc.data();
              final data = (rawData is Map) ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};

              final type = (data['type'] ?? 'UNKNOWN').toString();
              final status = (data['status'] ?? 'active').toString();
              final location = (data['location'] ?? 'Not specified').toString();
              final raisedBy = (data['raisedByEmail'] ?? 'Unknown').toString();
              final acknowledgedBy = data['acknowledgedByEmail']?.toString();

              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final timeStr = timestamp != null
                  ? "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} • ${timestamp.day}/${timestamp.month}/${timestamp.year}"
                  : "Just now";

              final isActive = status == 'active';

              Color cardColor = isActive ? Colors.white : Colors.green[50]!;
              Color statusColor = isActive ? Colors.red : Colors.green;
              String statusText = isActive ? "ACTIVE" : "ACKNOWLEDGED";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: cardColor,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Text(
                      type.isNotEmpty ? type[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    "$type Alert",
                    style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Location: $location"),
                      Text("Raised by: $raisedBy"),
                      Text("Time: $timeStr"),
                      const SizedBox(height: 8),
                      Text(
                        "Status: $statusText",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (acknowledgedBy != null)
                        Text("Acknowledged by: $acknowledgedBy", 
                          style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlertConfirmationScreen(
                          alertId: doc.id,
                          type: type,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}