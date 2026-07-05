import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/booking_log_model.dart';
import '../models/vehicle_model.dart';

/// Thrown when an atomic booking creation detects a resource conflict.
class BookingConflictException implements Exception {
  final String message;
  const BookingConflictException(this.message);
  @override
  String toString() => message;
}

/// TASK-10: one page of paginated history plus the cursor needed to fetch the
/// next page. [lastDoc] is the raw Firestore snapshot of the final item (fed
/// back as `startAfter`); [hasMore] is false once the last page is reached.
class BookingPage {
  final List<BookingModel> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
  const BookingPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });
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

  /// Otomatis ubah status kendaraan & supir menjadi inUse/onTrip
  /// untuk semua booking 'upcoming' yang waktu mulainya sudah lewat.
  Future<void> syncActiveStatuses() async {
    final now = DateTime.now();
    final snap = await _col
        .where('bookingStatus', isEqualTo: 'upcoming')
        .get();

    final batch = _db.batch();
    bool hasWork = false;

    for (final doc in snap.docs) {
      final b = BookingModel.fromFirestore(doc);
      if (now.isAfter(b.startDateTime) && now.isBefore(b.endDateTime)) {
        batch.update(doc.reference, {
          'bookingStatus': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (b.vehicleId.isNotEmpty) {
          batch.update(_db.collection('vehicles').doc(b.vehicleId), {
            'status': 'in_use',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        if (b.driverId.isNotEmpty) {
          batch.update(_db.collection('drivers').doc(b.driverId), {
            'status': 'on_trip',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        hasWork = true;
      }
    }

    if (hasWork) await batch.commit();
  }

  Stream<List<BookingModel>> streamActiveBookings() {
    return _col
        .where('bookingStatus', whereIn: ['upcoming', 'active'])
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(BookingModel.fromFirestore).toList();
      list.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      return list;
    });
  }

  Future<List<BookingModel>> getBookingsForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    // M-7: Both inequalities on same field -> no composite index needed.
    // TASK-04: use a 366-day lower bound so a long-running rental that STARTED
    // in a previous period but still spans the viewed month is not missed
    // (the old 90-day bound dropped such bookings). Still bounds the scan.
    final lowerBound = start.subtract(const Duration(days: 366));
    final snap = await _col
        .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(lowerBound))
        .where('startDateTime', isLessThan: Timestamp.fromDate(end))
        .get();

    return snap.docs
        .map(BookingModel.fromFirestore)
        .where((b) => !b.endDateTime.isBefore(start)) // endDateTime >= start
        .toList();
  }

  Stream<List<BookingModel>> streamBookingsForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final lowerBound = start.subtract(const Duration(days: 366));

    return _col
        .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(lowerBound))
        .where('startDateTime', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(BookingModel.fromFirestore)
          .where((b) => !b.endDateTime.isBefore(start))
          .toList();
    });
  }

  /// TASK-05: month query scoped to a single driver. Operators may only read
  /// their own assigned bookings, so their schedule must filter by driverId
  /// (satisfying the scoped Firestore read rule). Needs the composite index
  /// (driverId ASC, startDateTime ASC).
  Future<List<BookingModel>> getBookingsForMonthByDriver(
      String driverId, int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final lowerBound = start.subtract(const Duration(days: 366));
    final snap = await _col
        .where('driverId', isEqualTo: driverId)
        .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(lowerBound))
        .where('startDateTime', isLessThan: Timestamp.fromDate(end))
        .get();

    return snap.docs
        .map(BookingModel.fromFirestore)
        .where((b) => !b.endDateTime.isBefore(start))
        .toList();
  }

  Stream<List<BookingModel>> streamBookingsForMonthByDriver(
      String driverId, int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final lowerBound = start.subtract(const Duration(days: 366));

    return _col
        .where('driverId', isEqualTo: driverId)
        .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(lowerBound))
        .where('startDateTime', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(BookingModel.fromFirestore)
          .where((b) => !b.endDateTime.isBefore(start))
          .toList();
    });
  }

  Future<List<BookingModel>> getBookingsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    // M-7: same field inequalities.
    // TASK-04: 366-day lower bound so a long rental spanning this date but
    // started earlier is still included.
    final lowerBound = start.subtract(const Duration(days: 366));
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

  /// TASK-10: one page of history, carrying the cursor + hasMore so the
  /// ViewModel can append the next batch instead of replacing the list.
  /// [startAfter] is the raw [DocumentSnapshot] of the last item already shown.
  Future<BookingPage> getCompletedBookings({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    // All bookings, sorted by most recent activity — no status filter.
    // orderBy + limit pushed to Firestore so reads stay bounded (M-6).
    var query = _col.orderBy('updatedAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();

    return BookingPage(
      items: snap.docs.map(BookingModel.fromFirestore).toList(),
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      // A full page means there is (probably) more; a short page means the end.
      hasMore: snap.docs.length == limit,
    );
  }

  Future<bool> checkConflict({
    required String vehicleId,
    required String driverId,
    required DateTime start,
    required DateTime end,
    String? excludeBookingId,
    int bufferMinutes = 0,
  }) async {
    // Firestore tidak mendukung multiple inequality filters di field yang berbeda (start & end).
    // Jadi kita query statusnya saja, lalu filter tanggalnya secara lokal.
    final snap = await _col
        .where('bookingStatus', whereIn: ['upcoming', 'active'])
        .get();

    // TASK-03: expand each existing booking by the turnaround buffer on both
    // sides, so a new booking that starts within `bufferMinutes` of another
    // booking's end (or ends that close to another's start) is treated as a
    // conflict.
    final buffer = Duration(minutes: bufferMinutes);

    for (final doc in snap.docs) {
      if (excludeBookingId != null && doc.id == excludeBookingId) continue;
      final b = BookingModel.fromFirestore(doc);

      // Cek apakah tanggal tumpang tindih (overlap) termasuk buffer
      final bool isOverlap = b.startDateTime.subtract(buffer).isBefore(end) &&
          b.endDateTime.add(buffer).isAfter(start);

      if (isOverlap) {
        if (b.vehicleId == vehicleId || b.driverId == driverId) return true;
      }
    }
    return false;
  }

  /// TASK-01: atomic create with availability derived from date-overlap.
  ///
  /// Availability is the single source of truth via [checkConflict] (date
  /// overlap of active bookings) — NOT a global `vehicle.status == in_use`
  /// flag. A booking for a future date therefore no longer locks the vehicle
  /// for every other date, so multiple non-overlapping future bookings on the
  /// same vehicle are allowed.
  ///
  /// Flow:
  ///   1. ViewModel calls checkConflict first -> fast UI feedback.
  ///   2. This method re-runs the overlap check right before writing to tighten
  ///      the window between the UI check and the commit. (Firestore client
  ///      transactions cannot run queries, so this is the strongest in-SDK
  ///      guard; a per-slot lock doc / Cloud Function is the full race fix.)
  ///   3. The transaction only blocks a genuinely unavailable resource
  ///      (missing or in maintenance) and flags the vehicle/driver as currently
  ///      out *only* when the booking is active right now.
  Future<String> addWithLog(BookingModel booking, BookingLogModel log) async {
    final vehicleRef = _db.collection('vehicles').doc(booking.vehicleId);
    final driverRef  = _db.collection('drivers').doc(booking.driverId);

    // Final availability guard (date-overlap), as close to the write as possible.
    final conflict = await checkConflict(
      vehicleId: booking.vehicleId,
      driverId: booking.driverId,
      start: booking.startDateTime,
      end: booking.endDateTime,
    );
    if (conflict) {
      throw const BookingConflictException(
          'Jadwal bentrok dengan booking lain. Pilih kendaraan atau supir lain.');
    }

    return await _db.runTransaction<String>((txn) async {
      // --- reads first (Firestore transaction rule) ---
      final vSnap = await txn.get(vehicleRef);

      if (!vSnap.exists) {
        throw const BookingConflictException('Kendaraan tidak ditemukan.');
      }
      // Only an actually-unavailable vehicle blocks the booking — not a future
      // booking's status flag.
      if ((vSnap.data()?['status'] as String?) == VehicleStatus.maintenance.value) {
        throw const BookingConflictException('Kendaraan sedang dalam perbaikan.');
      }

      // --- writes ---
      final bookingRef = _col.doc();
      txn.set(bookingRef, booking.toFirestore());
      // subcollection log write in same transaction
      txn.set(bookingRef.collection('logs').doc(), log.toFirestore());

      // Reflect "currently out" only when the booking is active right now;
      // future bookings leave the vehicle/driver bookable for other dates.
      final now = DateTime.now();
      final isCurrent =
          !now.isBefore(booking.startDateTime) && now.isBefore(booking.endDateTime);
      if (isCurrent) {
        txn.update(vehicleRef, {
          'status': 'in_use',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        txn.update(driverRef, {
          'status': 'on_trip',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

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
      'bookingStatus': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // H-5: Guard empty IDs
    if (booking.vehicleId.isNotEmpty) {
      final vSnap = await _db.collection('vehicles').doc(booking.vehicleId).get();
      if ((vSnap.data()?['status']) != 'maintenance') {
        batch.update(vSnap.reference, {'status': 'ready', 'updatedAt': FieldValue.serverTimestamp()});
      }
    }
    if (booking.driverId.isNotEmpty) {
      batch.update(_db.collection('drivers').doc(booking.driverId), {
        'status': 'standby',
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
      'bookingStatus': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // H-5: Guard empty IDs
    if (booking.vehicleId.isNotEmpty) {
      final vSnap = await _db.collection('vehicles').doc(booking.vehicleId).get();
      if ((vSnap.data()?['status']) != 'maintenance') {
        batch.update(vSnap.reference, {'status': 'ready', 'updatedAt': FieldValue.serverTimestamp()});
      }
    }
    if (booking.driverId.isNotEmpty) {
      batch.update(_db.collection('drivers').doc(booking.driverId), {
        'status': 'standby',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(bookingRef.collection('logs').doc(), log.toFirestore());
    await batch.commit();
  }

  /// TASK-11: edit an existing booking's editable fields (customer, vehicle,
  /// driver, routes, schedule, price, payment) + write an activity log, in one
  /// batch. Availability is date-overlap based (TASK-01) so the caller re-runs
  /// [checkConflict] with `excludeBookingId` set to this booking before calling
  /// here; status flags stay best-effort "current" indicators.
  Future<void> updateBooking({
    required BookingModel updated,
    required BookingLogModel log,
  }) async {
    final batch = _db.batch();
    final bookingRef = _col.doc(updated.bookingId);
    batch.update(bookingRef, {
      'customerName': updated.customerName,
      'customerPhone': updated.customerPhone,
      'vehicleId': updated.vehicleId,
      'vehicleName': updated.vehicleName,
      'vehiclePlate': updated.vehiclePlate,
      'driverId': updated.driverId,
      'driverName': updated.driverName,
      'routes': updated.routes,
      'startDateTime': Timestamp.fromDate(updated.startDateTime),
      'endDateTime': Timestamp.fromDate(updated.endDateTime),
      'rentalPrice': updated.rentalPrice,
      'paymentStatus': updated.paymentStatus.value,
      'notes': updated.notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(bookingRef.collection('logs').doc(), log.toFirestore());
    await batch.commit();
  }

  /// TASK-11: all bookings for a given customer phone, most recent first.
  /// Needs the composite index (customerPhone ASC, startDateTime DESC).
  Future<List<BookingModel>> getBookingsByCustomerPhone(String phone) async {
    if (phone.isEmpty) return [];
    final snap = await _col
        .where('customerPhone', isEqualTo: phone)
        .orderBy('startDateTime', descending: true)
        .get();
    return snap.docs.map(BookingModel.fromFirestore).toList();
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
