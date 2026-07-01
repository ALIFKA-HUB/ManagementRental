import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rentalin/core/utils/app_time.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';
import 'package:rentalin/data/repositories/driver_repository.dart';

class ScheduleViewModel extends ChangeNotifier {
  final BookingRepository _repo = BookingRepository();
  final DriverRepository _driverRepo = DriverRepository();

  /// TASK-05: admins see the whole schedule; operators see only their own
  /// assigned trips (Firestore rules deny reading other bookings).
  final bool isAdmin;
  final String? userId;
  String? _driverId;

  ScheduleViewModel({this.isAdmin = true, this.userId});

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  Map<DateTime, List<BookingModel>> bookingsByDay = {};
  List<BookingModel> selectedDayBookings = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadMonth(DateTime month) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final List<BookingModel> bookings;
      if (isAdmin) {
        bookings = await _repo.getBookingsForMonth(month.year, month.month);
      } else {
        // Resolve the operator's driverId once, then scope the query to it.
        _driverId ??= (await _driverRepo.findByUserId(userId ?? ''))?.driverId;
        bookings = _driverId == null
            ? <BookingModel>[]
            : await _repo.getBookingsForMonthByDriver(_driverId!, month.year, month.month);
      }
      final map = <DateTime, List<BookingModel>>{};

      for (final b in bookings) {
        // Tambah ke setiap hari dalam rentang booking
        final start = _normalize(b.startDateTime);
        final end = _normalize(b.endDateTime);
        DateTime cur = start;
        while (!cur.isAfter(end)) {
          map.putIfAbsent(cur, () => []).add(b);
          cur = cur.add(const Duration(days: 1));
        }
      }

      bookingsByDay = map;
      _refreshSelectedDay();
    } on FirebaseException catch (e, st) {
      debugPrint('Firestore [${e.code}]: ${e.message}\n$st');
      errorMessage = switch (e.code) {
        'failed-precondition' => 'Konfigurasi database belum lengkap (index).',
        'permission-denied'   => 'Tidak punya akses ke data ini.',
        _ => 'Gagal memuat jadwal.',
      };
    } catch (e, st) {
      debugPrint('Unexpected: $e\n$st');
      errorMessage = 'Gagal memuat jadwal.';
    }

    isLoading = false;
    notifyListeners();
  }

  void selectDay(DateTime day, DateTime focused) {
    selectedDay = day;
    focusedDay = focused;
    _refreshSelectedDay();
    notifyListeners();
  }

  void _refreshSelectedDay() {
    selectedDayBookings = bookingsByDay[_normalize(selectedDay)] ?? [];
  }

  List<BookingModel> getEventsForDay(DateTime day) {
    return bookingsByDay[_normalize(day)] ?? [];
  }

  // TASK-04: bucket by WIB calendar day so a booking near midnight lands on the
  // correct day regardless of the device's local timezone. The same function is
  // applied to booking instants and to the calendar's day cells, keeping the
  // map keys and lookups consistent.
  DateTime _normalize(DateTime dt) => AppTime.wibDay(dt);
}
