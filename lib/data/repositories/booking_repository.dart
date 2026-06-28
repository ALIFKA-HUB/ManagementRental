import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/booking_log_model.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';

class BookingRepository {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('bookings');

  Future<List<BookingModel>> getActiveBookings() async {
    final snap = await _col
        .where('bookingStatus', whereIn: ['upcoming', 'active'])
        .orderBy('startDateTime')
        .get();
    return snap.docs.map(BookingModel.fromFirestore).toList();
  }

  Future<List<BookingModel>> getBookingsForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final snap = await _col
        .where('startDateTime', isLessThan: Timestamp.fromDate(end))
        .where('endDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();
    return snap.docs.map(BookingModel.fromFirestore).toList();
  }

  Future<List<BookingModel>> getBookingsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _col
        .where('startDateTime', isLessThan: Timestamp.fromDate(end))
        .where('endDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();
    return snap.docs.map(BookingModel.fromFirestore).toList();
  }

  Future<List<BookingModel>> getBookingsByDriver(String driverId) async {
    final snap = await _col
        .where('driverId', isEqualTo: driverId)
        .where('bookingStatus', whereIn: ['upcoming', 'active'])
        .orderBy('startDateTime')
        .get();
    return snap.docs.map(BookingModel.fromFirestore).toList();
  }

  Future<List<BookingModel>> getCompletedBookings({DocumentSnapshot? lastDoc}) async {
    var query = _col
        .where('bookingStatus', whereIn: ['completed', 'cancelled'])
        .orderBy('updatedAt', descending: true)
        .limit(20);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snap = await query.get();
    return snap.docs.map(BookingModel.fromFirestore).toList();
  }

  Future<bool> checkConflict({
    required String vehicleId,
    required String driverId,
    required DateTime start,
    required DateTime end,
    String? excludeBookingId,
  }) async {
    final snap = await _col
        .where('bookingStatus', whereIn: ['upcoming', 'active'])
        .where('startDateTime', isLessThan: Timestamp.fromDate(end))
        .where('endDateTime', isGreaterThan: Timestamp.fromDate(start))
        .get();

    for (final doc in snap.docs) {
      if (excludeBookingId != null && doc.id == excludeBookingId) continue;
      final b = BookingModel.fromFirestore(doc);
      if (b.vehicleId == vehicleId || b.driverId == driverId) return true;
    }
    return false;
  }

  Future<String> addWithLog(BookingModel booking, BookingLogModel log) async {
    final batch = _db.batch();
    final bookingRef = _col.doc();
    batch.set(bookingRef, booking.toFirestore());
    final logRef = bookingRef.collection('logs').doc();
    batch.set(logRef, log.toFirestore());
    await batch.commit();
    return bookingRef.id;
  }

  Future<void> cancelBooking({
    required String bookingId,
    required BookingLogModel log,
  }) async {
    final batch = _db.batch();
    final bookingRef = _col.doc(bookingId);
    final snap = await bookingRef.get();
    final booking = BookingModel.fromFirestore(snap);

    batch.update(bookingRef, {
      'bookingStatus': BookingStatus.cancelled.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('vehicles').doc(booking.vehicleId), {
      'status': VehicleStatus.ready.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('drivers').doc(booking.driverId), {
      'status': DriverStatus.standby.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(bookingRef.collection('logs').doc(), log.toFirestore());
    await batch.commit();
  }

  Future<void> completeBooking({
    required String bookingId,
    required BookingLogModel log,
  }) async {
    final batch = _db.batch();
    final bookingRef = _col.doc(bookingId);
    final snap = await bookingRef.get();
    final booking = BookingModel.fromFirestore(snap);

    batch.update(bookingRef, {
      'bookingStatus': BookingStatus.completed.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('vehicles').doc(booking.vehicleId), {
      'status': VehicleStatus.ready.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('drivers').doc(booking.driverId), {
      'status': DriverStatus.standby.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(bookingRef.collection('logs').doc(), log.toFirestore());
    await batch.commit();
  }

  Future<void> extendBooking({
    required String bookingId,
    required DateTime newEnd,
    required double extraPrice,
    required BookingLogModel log,
  }) async {
    final batch = _db.batch();
    final bookingRef = _col.doc(bookingId);
    final snap = await bookingRef.get();
    final booking = BookingModel.fromFirestore(snap);

    batch.update(bookingRef, {
      'endDateTime': Timestamp.fromDate(newEnd),
      'rentalPrice': booking.rentalPrice + extraPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(bookingRef.collection('logs').doc(), log.toFirestore());
    await batch.commit();
  }

  Future<void> updatePaymentStatus({
    required String bookingId,
    required PaymentStatus newStatus,
    required BookingLogModel log,
  }) async {
    final batch = _db.batch();
    final bookingRef = _col.doc(bookingId);
    batch.update(bookingRef, {
      'paymentStatus': newStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(bookingRef.collection('logs').doc(), log.toFirestore());
    await batch.commit();
  }
}
