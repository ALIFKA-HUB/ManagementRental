import 'package:cloud_firestore/cloud_firestore.dart';

class BookingLogModel {
  final String logId;
  final String action;
  final String performedBy;
  final String performedByName;
  final String? note;
  final DateTime timestamp;

  const BookingLogModel({
    required this.logId,
    required this.action,
    required this.performedBy,
    required this.performedByName,
    this.note,
    required this.timestamp,
  });

  factory BookingLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookingLogModel(
      logId: doc.id,
      action: d['action'] ?? '',
      performedBy: d['performedBy'] ?? '',
      performedByName: d['performedByName'] ?? '',
      note: d['note'],
      timestamp: (d['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'action': action,
        'performedBy': performedBy,
        'performedByName': performedByName,
        'note': note,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
