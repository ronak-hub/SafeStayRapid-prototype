import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'alert_confirmation_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Team Dashboard - Live Alerts"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .where('status', isEqualTo: 'active')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 24),
                    const Text(
                      "Failed to load alerts",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error details:\n${snapshot.error.toString()}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    "No active alerts right now.",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "All clear! ✓",
                    style: TextStyle(fontSize: 18, color: Colors.green),
                  ),
                ],
              ),
            );
          }

          final alerts = snapshot.data!.docs;

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final doc = alerts[index];
                final data = doc.data() as Map<String, dynamic>;

                final type = data['type'] ?? 'UNKNOWN';
                final raisedByEmail = data['raisedByEmail'] ?? 'unknown';
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                final timeStr = timestamp != null
                    ? "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} • ${timestamp.day}/${timestamp.month}/${timestamp.year}"
                    : 'just now';

                final status = data['status'] ?? 'active';
                final location = data['location'] ?? 'Not specified';

                Color typeColor = Colors.red;
                if (type.contains("MEDICAL")) typeColor = Colors.orange;
                if (type.contains("SECURITY")) typeColor = Colors.purple;
                if (type.contains("FOOD")) typeColor = Colors.deepOrange;
                if (type.contains("NATURAL")) typeColor = Colors.brown;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: typeColor,
                      radius: 28,
                      child: Text(
                        type[0],
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      "$type Alert",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Raised by: $raisedByEmail"),
                        Text("Location: $location"),
                        Text("Time: $timeStr"),
                        const SizedBox(height: 8),

                        if (status == 'acknowledged') ...[
                          Text(
                            "Acknowledged by: ${data['acknowledgedByEmail'] ?? 'Unknown'}",
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "ETA: ${data['eta'] ?? 'Not set'} min",
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ] else ...[
                          Text(
                            "Status: Active – Awaiting response",
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                      ],
                    ),
                    trailing: status == 'active'
                        ? ElevatedButton(
                            onPressed: () => _acknowledgeAlert(context, doc.id, raisedByEmail),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(110, 36),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text("Acknowledge", style: TextStyle(fontSize: 12)),
                          )
                        : const Icon(Icons.check_circle, color: Colors.green, size: 32),
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
            ),
          );
        },
      ),
    );
  }

  // Acknowledge alert with ETA dialog
  Future<void> _acknowledgeAlert(BuildContext context, String alertId, String raisedByEmail) async {
    if (!context.mounted) return;

    String? eta;

    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController etaCtrl = TextEditingController(text: '3');
        return AlertDialog(
          title: const Text("ETA to Respond (minutes)"),
          content: TextField(
            controller: etaCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "e.g. 3"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                eta = etaCtrl.text.trim();
                if (eta!.isEmpty) eta = 'Not set';
                Navigator.pop(context);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (eta == null || !context.mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance.collection('alerts').doc(alertId).update({
        'status': 'acknowledged',
        'acknowledgedBy': currentUser.uid,
        'acknowledgedByEmail': currentUser.email ?? 'Staff',
        'acknowledgedAt': FieldValue.serverTimestamp(),
        'eta': eta,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Acknowledged – ETA: $eta min"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}