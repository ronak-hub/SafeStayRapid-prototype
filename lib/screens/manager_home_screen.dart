import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'alert_confirmation_screen.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Dashboard"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .where('status', isEqualTo: 'active')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading alerts"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 90, color: Colors.green),
                  const SizedBox(height: 24),
                  const Text(
                    "All Clear",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "No active alerts at the moment.\nGreat job keeping everyone safe!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
              final doc = alerts[index];
              final data = doc.data() as Map<String, dynamic>;

              final type = data['type'] ?? 'UNKNOWN';
              final raisedByEmail = data['raisedByEmail'] ?? 'Unknown';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final timeStr = timestamp != null
                  ? "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} • ${timestamp.day}/${timestamp.month}"
                  : 'Just now';

              final location = data['location'] ?? 'Not specified';
              final eta = data['eta'] ?? 'Not set';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: type == 'FIRE' ? Colors.red : Colors.orange,
                            radius: 28,
                            child: Text(
                              type[0],
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("$type Alert", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text("Raised by: $raisedByEmail"),
                                Text("Location: $location"),
                                Text("Time: $timeStr"),
                                Text("ETA: $eta"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // SOP Progress
                      if (data['sopProgress'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("SOP Progress:", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...(data['sopProgress'] as Map<String, dynamic>).entries.map((entry) {
                              final step = entry.key;
                              final completed = entry.value as bool? ?? false;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      completed ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: completed ? Colors.green : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(step)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Respond Now"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('alerts')
                                    .doc(doc.id)
                                    .update({'status': 'resolved'});

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Alert marked as resolved"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Mark Resolved"),
                            ),
                          ),
                        ],
                      ),
                    ],
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