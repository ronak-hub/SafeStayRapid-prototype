import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/escalation_helper.dart';
import 'sop_checklist_screen.dart';

class AlertConfirmationScreen extends StatefulWidget {
  final String alertId;
  final String type;

  const AlertConfirmationScreen({
    super.key,
    required this.alertId,
    required this.type,
  });

  @override
  State<AlertConfirmationScreen> createState() => _AlertConfirmationScreenState();
}

class _AlertConfirmationScreenState extends State<AlertConfirmationScreen> {
  bool isManager = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.type} ALERT"),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('alerts').doc(widget.alertId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String locationText = "Location not available";
          String raisedBy = FirebaseAuth.instance.currentUser?.email ?? 'Staff';
          String timeText = "Just now";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            locationText = data['location'] ?? "Location not available";
            raisedBy = data['raisedByEmail'] ?? raisedBy;
            final ts = (data['timestamp'] as Timestamp?)?.toDate();
            timeText = ts != null
                ? "${ts.hour}:${ts.minute.toString().padLeft(2, '0')} • ${ts.day}/${ts.month}/${ts.year}"
                : "Just now";
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.type} at $locationText",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Raised by: $raisedBy\nTime: $timeText",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),

                // Isolated Countdown (no flicker)
                CountdownTimer(initialSeconds: 60, alertId: widget.alertId),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SopChecklistScreen(
                          alertId: widget.alertId,
                          alertType: widget.type,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    "View SOP Checklist",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Acknowledged! Team notified."),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 65),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "I AM RESPONDING",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Alert cancelled successfully"),
                        backgroundColor: Colors.grey,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.transparent,
                  ),
                  child: const Text(
                    "Cancel Alert (Manager Only)",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {
                    final summary = EscalationHelper.buildIndianEmergencySummary(
                      alertId: widget.alertId,
                      type: widget.type,
                      locationText: locationText,
                      raisedByEmail: raisedBy,
                      timeText: timeText,
                    );

                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (ctx) {
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "External escalation (India)",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Use these numbers only when hotel SOPs are insufficient or the situation is critical.",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _EmergencyChip(
                                      label: "All-in-one 112",
                                      number: EscalationHelper.emergencyAllInOne,
                                    ),
                                    _EmergencyChip(
                                      label: "Police 100",
                                      number: EscalationHelper.police,
                                    ),
                                    _EmergencyChip(
                                      label: "Fire 101",
                                      number: EscalationHelper.fire,
                                    ),
                                    _EmergencyChip(
                                      label: "Ambulance 102",
                                      number: EscalationHelper.ambulance,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Suggested script (you can read this out):",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SelectableText(
                                    summary,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.emergency_share),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: const Text(
                    "Escalate to external services",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                const Spacer(),
                const Text(
                  "Real-time team dashboard coming soon",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Separate widget - only this rebuilds every 5 seconds (no flicker on main screen)
class CountdownTimer extends StatefulWidget {
  final int initialSeconds;
  final String alertId;

  const CountdownTimer({
    super.key,
    required this.initialSeconds,
    required this.alertId,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _secondsLeft;
  late Timer _timer;
  bool _escalated = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.initialSeconds;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      var escalatedNow = false;
      setState(() {
        if (_secondsLeft > 0 && !_escalated) {
          _secondsLeft -= 5;
          if (_secondsLeft < 0) {
            _secondsLeft = 0;
          }
        }

        if (_secondsLeft <= 0 && !_escalated) {
          timer.cancel();
          _escalated = true;
          escalatedNow = true;
        }
      });

      if (escalatedNow && mounted) {
        debugPrint('AUTO-ESCALATION for alert ${widget.alertId}');
        FirebaseFirestore.instance
            .collection('alerts')
            .doc(widget.alertId)
            .update(EscalationHelper.buildAutoEscalationUpdate())
            .catchError((Object e, _) {
          debugPrint('Failed to write escalation metadata: $e');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Auto-escalation triggered – consider calling external responders"),
            backgroundColor: Colors.deepOrange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondsLeft <= 10 || _escalated ? Colors.red[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _escalated
            ? "Escalation triggered!"
            : "$_secondsLeft seconds until auto-escalation",
        style: TextStyle(
          fontSize: 18,
          color: _secondsLeft <= 10 || _escalated ? Colors.red : Colors.orange.shade900,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EmergencyChip extends StatelessWidget {
  const _EmergencyChip({
    required this.label,
    required this.number,
  });

  final String label;
  final String number;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.phone_in_talk, size: 16),
      label: Text('$label ($number)'),
    );
  }
}