import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Wraps the app with a thin status bar driven by [ConnectionState] and
/// Firestore snapshot metadata (server vs cache).
class FirebaseConnectionWrapper extends StatelessWidget {
  const FirebaseConnectionWrapper({
    super.key,
    required this.child,
    this.firebaseInitError,
  });

  final Widget child;
  final Object? firebaseInitError;

  static final DocumentReference<Map<String, dynamic>> _healthDoc =
      FirebaseFirestore.instance.collection('_health').doc('ping');

  @override
  Widget build(BuildContext context) {
    if (firebaseInitError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusBar(
            color: Colors.red.shade900,
            icon: Icons.error_outline,
            title: 'Firebase failed to start',
            subtitle: '$firebaseInitError',
          ),
          Expanded(child: child),
        ],
      );
    }

    if (Firebase.apps.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusBar(
            color: Colors.orange.shade900,
            icon: Icons.hourglass_empty,
            title: 'Firebase',
            subtitle: 'Not initialized',
          ),
          Expanded(child: child),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _healthDoc.snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        final meta = snapshot.data?.metadata;
        final fromCache = meta?.isFromCache ?? true;
        final hasPending = meta?.hasPendingWrites ?? false;

        late final _BarSpec spec;
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            spec = _BarSpec(
              color: Colors.blueGrey.shade700,
              icon: Icons.cloud_queue,
              title: 'Firebase',
              subtitle: 'Connecting to Firestore… (${snapshot.connectionState.name})',
            );
          case ConnectionState.active:
            if (snapshot.hasError) {
              spec = _BarSpec(
                color: Colors.deepOrange.shade900,
                icon: Icons.cloud_off,
                title: 'Firestore',
                subtitle: 'Error: ${snapshot.error}',
              );
            } else if (!fromCache) {
              spec = _BarSpec(
                color: Colors.green.shade800,
                icon: Icons.cloud_done,
                title: 'Firestore',
                subtitle: hasPending
                    ? 'Connected — syncing changes…'
                    : 'Connected — live from server',
              );
            } else {
              spec = _BarSpec(
                color: Colors.amber.shade900,
                icon: Icons.cloud_sync,
                title: 'Firestore',
                subtitle: 'Using cache or waiting for server — check network',
              );
            }
          case ConnectionState.done:
            spec = _BarSpec(
              color: Colors.blueGrey.shade800,
              icon: Icons.cloud,
              title: 'Firestore',
              subtitle: 'Stream closed (${snapshot.connectionState.name})',
            );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusBar(
              color: spec.color,
              icon: spec.icon,
              title: spec.title,
              subtitle: spec.subtitle,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _BarSpec {
  const _BarSpec({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
