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
  List<Map<String, dynamic>> _steps = [];
  bool _isLoading = true;
  bool _allDone = false;

  @override
  void initState() {
    super.initState();
    _loadSopStepsAndProgress();
  }

  Future<void> _loadSopStepsAndProgress() async {
    // Load dummy steps based on type
    switch (widget.alertType.toUpperCase()) {
      case 'FIRE':
        _steps = [
          {'step': 'Sound fire alarm', 'done': false},
          {'step': 'Evacuate guests → Assembly Point B', 'done': false},
          {'step': 'Call Fire Brigade – 101', 'done': false},
          {'step': 'Check for trapped guests', 'done': false},
          {'step': 'Shut down elevators & AC', 'done': false},
          {'step': 'Headcount at Assembly Point', 'done': false},
        ];
        break;
      case 'MEDICAL':
        _steps = [
          {'step': 'Call ambulance – 108', 'done': false},
          {'step': 'Provide first aid if trained', 'done': false},
          {'step': 'Clear area around patient', 'done': false},
          {'step': 'Notify hotel doctor/security', 'done': false},
          {'step': 'Prepare guest info for paramedics', 'done': false},
        ];
        break;
      case 'SECURITY':
        _steps = [
          {'step': 'Notify security team', 'done': false},
          {'step': 'Secure the area', 'done': false},
          {'step': 'Call police if needed – 100', 'done': false},
          {'step': 'Check CCTV footage', 'done': false},
          {'step': 'Escort guests to safe zone', 'done': false},
        ];
        break;
      default:
        _steps = [
          {'step': 'Assess situation', 'done': false},
          {'step': 'Notify relevant team', 'done': false},
          {'step': 'Follow standard protocol', 'done': false},
        ];
    }

    // Load saved progress from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('alerts')
          .doc(widget.alertId)
          .get();

      if (doc.exists && doc['sopProgress'] != null) {
        final savedProgress = List<bool>.from(doc['sopProgress']);
        if (savedProgress.length == _steps.length) {
          for (int i = 0; i < _steps.length; i++) {
            _steps[i]['done'] = savedProgress[i];
          }
        }
      }
    } catch (e) {
      // No print – silent error handling for production
    }

    // Check if all done
    _allDone = _steps.every((step) => step['done'] == true);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStep(int index, bool value) async {
    setState(() {
      _steps[index]['done'] = value;
      _allDone = _steps.every((step) => step['done'] == true);
    });

    // Save progress to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('alerts')
          .doc(widget.alertId)
          .update({
        'sopProgress': _steps.map((step) => step['done']).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'allStepsCompleted': _allDone,
      });
    } catch (e) {
      // Silent error – no print in production
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.alertType} – SOP Checklist"),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Follow these steps for ${widget.alertType} alert",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_allDone)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "All steps completed! ✓ Incident under control",
                        style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _steps.length,
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        return CheckboxListTile(
                          title: Text(
                            step['step'],
                            style: TextStyle(
                              decoration: step['done'] ? TextDecoration.lineThrough : null,
                              color: step['done'] ? Colors.grey : Colors.black,
                            ),
                          ),
                          value: step['done'],
                          onChanged: (bool? value) => _toggleStep(index, value ?? false),
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Back to Dashboard", style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
    );
  }
}