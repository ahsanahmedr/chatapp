enum PendingStatus { sending, failed }

/// A message that hasn't been confirmed as saved to Firestore yet.
/// Shown locally with a "Sending..." or "Not sent" indicator.
class PendingMessage {
  final String id;
  final String text;
  final DateTime timestamp;
  PendingStatus status;

  PendingMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    this.status = PendingStatus.sending,
  });
}