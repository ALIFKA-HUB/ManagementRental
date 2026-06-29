import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/booking_log_model.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';

/// Thrown when an atomic booking creation detects a resource conflict.
class BookingConflictException implements Exception {
  final String message;
  const BookingConflictException(this.message);
  @override
  String toString() => message;
}

class BookingRepository {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('bookings');

  Future<List<BookingModel>> getActiveBookings() async {
    final snap = await _col
        .where('bookingStatus', whereIn: ['upcoming', 'active'])
        .get();
    final list = snap.docs.map(BookingModel.fromFirestore).toList();
    list.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return list;
  }

  Future<List<BookingModel>> getBookingsForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    // M-7: Both inequalities on same field → no composite index needed.
    // 90-day lower bound prevents full history scan.
    final lowerBound = start.subtract(const Duration(days: 90));
    final snap = await _col
        .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(lowerBound))
        .where('startDateTime', isLessThan: Timestamp.fromDate(end))
        .get();

    return snap.docs
        .map(BookingModel.fromFirestore)
        .where((b) => !b.endDateTime.isBefore(start)) // endDateTime >= start
        .toList();
  }

  Future<List<BookingModel>> getBookingsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    // M-7: same field inequalities; 90-day guard is sufficient for a single date.
    final lowerBound = start.subtract(const Duration(days: 90));
    final snap = await _col
        .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(lowerBound))
        .where('startDateTime', isLessThan: Timestamp.fromDate(end))
        .get();

    return snap.docs
        .map(BookingModel.fromFirestore)
        .where((b) => !b.endDateTime.isBefore(start))
        .toList();
  }

  Future<List<BookingModel>> getBookingsByDriver(String driverId) async {
    final snap = await _col
        .where('driverId', isEqualTo: driverId)
        .where('bookingStatus', whereIn: ['upcoming', 'active'])
        .get();
    final list = snap.docs.map(BookingModel.fromFirestore).toList();
    list.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return list;
  }

  Future<List<BookingModel>> getCompletedBookings({DocumentSnapshot? lastDoc}) async {
    // M-6: push orderBy + limit to Firestore so reads don't grow unbounded.
    // Requires composite index: bookingStatus ASC, updatedAt DESC (in firestore.indexes.json).
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
    // Firestore tidak mendukung multiple inequality filters di field yang berbeda (start & end).
    // Jadi kita query statusnya saja, lalu filter tanggalnya secara lokal.
    final snap = await _col
        .where('bookingStatus', whereIn: ['upcoming', 'active'])
        .get();

    for (final doc in snap.docs) {
      if (excludeBookingId != null && doc.id == excludeBookingId) continue;
      final b = BookingModel.fromFirestore(doc);
      
      // Cek apakah tanggal tumpang tindih (overlap)
      final bool isOverlap = b.startDateTime.isBefore(end) && b.endDateTime.isAfter(start);
      
      if (isOverlap) {
        if (b.vehicleId == vehicleId || b.driverId == driverId) return true;
      }
    }
    return false;
  }

  /// M-1 fix: atomic create with final status guard inside runTransaction.
  ///
  /// Flow:
  ///   1. ViewModel calls checkConflict first → fast UI feedback.
  ///   2. This method runs a transaction that re-reads vehicle & driver status
  ///      as the real guard. If another admin grabbed the resource between
  ///      the conflict check and this write, the transaction aborts with
  ///      [BookingConflictException] instead of silently double-booking.
  Future<String> addWithLog(BookingModel booking, BookingLogModel log) async {
    final vehicleRef = _db.collection('vehicles').doc(booking.vehicleId);
    final driverRef  = _db.collection('drivers').doc(booking.driverId);

    return await _db.runTransaction<String>((txn) async {
      // --- reads first (Firestore transaction rule) ---
      final vSnap = await txn.get(vehicleRef);
      final dSnap = await txn.get(driverRef);

      final vStatus = vSnap.data()?['status'] as String?;
      final dStatus = dSnap.data()?['status'] as String?;

      // Final guard: if resource was grabbed since our conflict check, abort.
      if (vStatus == VehicleStatus.inUse.value) {
        throw const BookingConflictException('Kendaraan sudah diambil booking lain. Pilih kendaraan lain.');
      }
      if (dStatus == DriverStatus.onTrip.value) {
        throw const BookingConflictException('Supir sudah diambil booking lain. Pilih supir lain.');
      }

      // --- writes ---
      final bookingRef = _col.doc();
      txn.set(bookingRef, booking.toFirestore());
      // ponytail: subcollection log write in same transaction
      txn.set(bookingRef.collection('logs').doc(), log.toFirestore());
      txn.update(vehicleRef, {
        'status': VehicleStatus.inUse.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      txn.update(driverRef, {
        'status': DriverStatus.onTrip.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return bookingRef.id;
    });
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

    // H-5: Guard empty IDs
    if (booking.vehicleId.isNotEmpty) {
      final vSnap = await _db.collection('vehicles').doc(booking.vehicleId).get();
      if ((vSnap.data()?['status']) != VehicleStatus.maintenance.value) {
        batch.update(vSnap.reference, {'status': VehicleStatus.ready.value, 'updatedAt': FieldValue.serverTimestamp()});
      }
    }
    if (booking.driverId.isNotEmpty) {
      batch.update(_db.collection('drivers').doc(booking.driverId), {
        'status': DriverStatus.standby.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
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

    // H-5: Guard empty IDs
    if (booking.vehicleId.isNotEmpty) {
      final vSnap = await _db.collection('vehicles').doc(booking.vehicleId).get();
      if ((vSnap.data()?['status']) != VehicleStatus.maintenance.value) {
        batch.update(vSnap.reference, {'status': VehicleStatus.ready.value, 'updatedAt': FieldValue.serverTimestamp()});
      }
    }
    if (booking.driverId.isNotEmpty) {
      batch.update(_db.collection('drivers').doc(booking.driverId), {
        'status': DriverStatus.standby.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
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
