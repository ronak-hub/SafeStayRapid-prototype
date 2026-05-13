import 'package:cloud_firestore/cloud_firestore.dart';

/// Static helpers for escalation metadata and human-readable summaries.
class EscalationHelper {
  /// Phone numbers used in Indian emergency context.
  static const String emergencyAllInOne = '112';
  static const String police = '100';
  static const String fire = '101';
  static const String ambulance = '102';

  /// Your primary test / escalation contact (hotel security / GM).
  ///
  /// This is currently set to the number you provided for testing.
  static const String primaryPropertyContact = '+917014862823';

  /// Fields we write into an alert document when auto-escalation is triggered.
  ///
  /// This is a pure helper so that backend code (Cloud Functions) and
  /// frontend widgets can share the same structure.
  static Map<String, Object?> buildAutoEscalationUpdate() {
    return <String, Object?>{
      'escalationLevel': 'external_recommended',
      'escalationReason': 'No responder acknowledged within configured timer.',
      'escalatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Builds a concise, India-appropriate summary that a human can read aloud
  /// to 112 / police / fire / ambulance.
  ///
  /// You can later replace this implementation with a call to an LLM
  /// (for example using the google_generative_ai package) while keeping
  /// the signature stable.
  static String buildIndianEmergencySummary({
    required String alertId,
    required String type,
    required String locationText,
    required String raisedByEmail,
    required String timeText,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('This is an escalation from a hotel safety system.');
    buffer.writeln('Alert type: $type.');
    buffer.writeln('Approximate location: $locationText.');
    buffer.writeln('Raised by: $raisedByEmail at $timeText.');
    buffer.writeln('Internal reference ID: $alertId.');
    buffer.writeln(
      'Primary on-site contact for coordination: $primaryPropertyContact.',
    );
    buffer.writeln(
      'Please treat this as a potential emergency until confirmed safe.',
    );
    return buffer.toString();
  }
}

