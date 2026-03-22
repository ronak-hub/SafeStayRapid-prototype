import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // For real device location

import 'alert_confirmation_screen.dart';
import 'dashboard_screen.dart'; // adjust name if different

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> raiseAlert(String type) async {
    if (!mounted) return;

    String location = 'Location not available'; // fallback if permission denied

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enable location services in settings")),
          );
        }
        // continue with fallback location
      } else {
        // 2. Check & request permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Location permission denied")),
              );
            }
            // continue with fallback
          }
        }

        if (permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Location permission denied forever – enable in app settings"),
              ),
            );
          }
          // continue with fallback
        } else {
          // 3. Get current position (modern way – no deprecated desiredAccuracy)
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10, // only update if moved >10 meters (optional)
            ),
          );

          location = "Lat: ${position.latitude.toStringAsFixed(6)}, "
              "Lng: ${position.longitude.toStringAsFixed(6)} "
              "(±${position.accuracy.toStringAsFixed(0)} m)";
        }
      }

      // 4. Save alert with real (or fallback) location
      final docRef = await FirebaseFirestore.instance.collection('alerts').add({
        'type': type,
        'raisedBy': user?.uid ?? 'unknown',
        'raisedByEmail': user?.email ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'location': location, // real GPS coordinates!
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertConfirmationScreen(
            alertId: docRef.id,
            type: type,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error raising alert: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SafeStay Rapid"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.white),
            tooltip: "Team Dashboard",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Welcome, Duty Manager",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tap to raise emergency alert",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildEmergencyButton("FIRE", Colors.red),
                  _buildEmergencyButton("MEDICAL", Colors.red),
                  _buildEmergencyButton("SECURITY", Colors.red),
                  _buildEmergencyButton("NATURAL DISASTER", Colors.red),
                  _buildEmergencyButton("FOOD SAFETY", Colors.red),
                ],
              ),
            ),

            const Text(
              "Silent Panic Mode: Long press any button",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(String label, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => raiseAlert(label),
      child: Text(
        label,
        style: TextStyle(
          fontSize: label.length > 12 ? 14 : 18,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}