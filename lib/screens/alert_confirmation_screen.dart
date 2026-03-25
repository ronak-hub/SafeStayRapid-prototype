// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  bool _isManager = false;
  bool _isLoading = false;

  int _secondsLeft = 60;
  late Timer _timer;
  bool _escalated = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _startTimer();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _isManager = doc['role'] == 'manager';
        });
      }
    } catch (e) {
      print("Error loading role: $e");
      setState(() => _isManager = false); // Default to staff
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_secondsLeft > 0 && !_escalated) {
          _secondsLeft -= 5;
          if (_secondsLeft < 0) _secondsLeft = 0;
        }

        if (_secondsLeft <= 0 && !_escalated) {
          timer.cancel();
          _escalated = true;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Auto-escalation triggered – notifying external responders"),
                backgroundColor: Colors.deepOrange,
              ),
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> acknowledge() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('alerts')
          .doc(widget.alertId)
          .update({
        'status': 'acknowledged',
        'acknowledgedBy': FirebaseAuth.instance.currentUser?.email ?? 'Staff',
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Acknowledged! Team notified."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to acknowledge"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> cancelAlert() async {
    if (!mounted) return;
    if (!_isManager) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only Managers can cancel alerts"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('alerts')
          .doc(widget.alertId)
          .delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Alert cancelled successfully"),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to cancel alert"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.type} ALERT"),
        backgroundColor: Colors.red,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              _isManager ? "👑 Manager" : "👤 Staff",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${widget.type} Alert",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("ID: ${widget.alertId}"),
              const SizedBox(height: 30),

              // Timer Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _secondsLeft <= 10 || _escalated ? Colors.red[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _escalated ? "Escalation triggered!" : "$_secondsLeft seconds until auto-escalation",
                  style: TextStyle(
                    fontSize: 18,
                    color: _secondsLeft <= 10 || _escalated ? Colors.red : Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

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
                child: const Text("View SOP Checklist", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),

              const SizedBox(height: 40),

              // Green Button
              ElevatedButton(
                onPressed: _isLoading ? null : acknowledge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("I AM RESPONDING", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 16),

              // Cancel Button - Only visible/enabled for Manager
              ElevatedButton(
                onPressed: _isLoading || !_isManager ? null : cancelAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "Cancel Alert (Manager Only)",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Real-time team dashboard coming soon",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}