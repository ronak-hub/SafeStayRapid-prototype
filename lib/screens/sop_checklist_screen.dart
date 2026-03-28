import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SopChecklistScreen extends StatefulWidget {
  final String alertId;
  final String alertType;

  const SopChecklistScreen({
    super.key,
    required this.alertId,
    required this.alertType,
  });

  @override
  State<SopChecklistScreen> createState() => _SopChecklistScreenState();
}

class _SopChecklistScreenState extends State<SopChecklistScreen> {
  final Map<String, bool> _checkedItems = {};

  List<String> getSopSteps() {
    switch (widget.alertType.toUpperCase()) {
      case 'FIRE':
        return [
          "Activate fire alarm",
          "Evacuate guests to assembly point",
          "Call fire department (101)",
          "Use fire extinguisher if safe",
          "Close fire doors",
          "Account for all staff and guests",
        ];
      case 'MEDICAL':
        return [
          "Assess the patient's condition",
          "Call ambulance (108)",
          "Provide first aid if trained",
          "Clear area for medical team",
          "Inform family if known",
        ];
      case 'SECURITY':
        return [
          "Alert security team",
          "Lock down affected area",
          "Call police (100)",
          "Gather witness statements",
          "Review CCTV if available",
        ];
      default:
        return ["Follow standard emergency protocol"];
    }
  }

  Future<void> _saveProgress() async {
    try {
      await FirebaseFirestore.instance.collection('alerts').doc(widget.alertId).update({
        'sopProgress': _checkedItems,           // Save as Map (safe)
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("SOP progress saved"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = getSopSteps();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.alertType} SOP Checklist"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                _checkedItems.putIfAbsent(step, () => false);

                return CheckboxListTile(
                  title: Text(step),
                  value: _checkedItems[step],
                  onChanged: (bool? value) {
                    setState(() {
                      _checkedItems[step] = value ?? false;
                    });
                    _saveProgress(); // Auto-save on change
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveProgress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save Progress", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}