import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_log_model.dart';

class BookingLogRepository {
  final _db = FirebaseFirestore.instance;

  Future<List<BookingLogModel>> getLogsForBooking(String bookingId) async {
    final snap = await _db
        .collection('bookings')
        .doc(bookingId)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map(BookingLogModel.fromFirestore).toList();
  }

  Future<void> addLog(String bookingId, BookingLogModel log) async {
    await _db
        .collection('bookings')
        .doc(bookingId)
        .collection('logs')
        .add(log.toFirestore());
  }
}
