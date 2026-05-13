import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Guest/customer: [showAllAlerts] is false — only alerts raised by this user.
/// Manager: [showAllAlerts] is true — entire venue alert history (newest first).
class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({
    super.key,
    this.showAllAlerts = false,
  });

  final bool showAllAlerts;

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see history')),
      );
    }

    if (!showAllAlerts) {
      return _HistoryScaffold(
        title: 'My alert history',
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .where('raisedBy', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        showRaiser: false,
      );
    }

    return _HistoryScaffold(
      title: 'All alert history',
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .limit(500)
          .snapshots(),
      showRaiser: true,
    );
  }
}

class _HistoryScaffold extends StatelessWidget {
  const _HistoryScaffold({
    required this.title,
    required this.stream,
    required this.showRaiser,
  });

  final String title;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final bool showRaiser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snapshot.error}\n'
                  'If this mentions an index, deploy Firestore indexes.',
                  textAlign: TextAlign.center,
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
                  Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    showRaiser ? 'No alerts in history yet' : 'No alerts raised by you yet',
                    style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
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
              final data = alerts[index].data();
              final type = data['type'] ?? 'UNKNOWN';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final timeStr = timestamp != null
                  ? '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} • '
                      '${timestamp.day}/${timestamp.month}/${timestamp.year}'
                  : 'Just now';
              final location = data['location'] ?? 'Not specified';
              final status = (data['status'] ?? 'active').toString();
              final email = data['raisedByEmail'] ?? 'Unknown';
              final userType = data['userType'] ?? '';

              final subtitle = StringBuffer('Time: $timeStr\nLocation: $location');
              if (showRaiser) {
                subtitle.write('\nRaised by: $email');
                if (userType.toString().isNotEmpty) {
                  subtitle.write(' ($userType)');
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  isThreeLine: showRaiser,
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: status == 'active' ? Colors.red : Colors.green,
                    size: 40,
                  ),
                  title: Text(
                    '$type Alert',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    subtitle.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Chip(
                    label: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: status == 'active' ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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
