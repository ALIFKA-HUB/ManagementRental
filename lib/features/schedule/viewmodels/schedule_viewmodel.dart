import 'dart:async';
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

  StreamSubscription<List<BookingModel>>? _monthSub;

  @override
  void dispose() {
    _monthSub?.cancel();
    super.dispose();
  }

  Future<void> loadMonth(DateTime month) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final Stream<List<BookingModel>> stream;
      if (isAdmin) {
        stream = _repo.streamBookingsForMonth(month.year, month.month);
      } else {
        _driverId ??= (await _driverRepo.findByUserId(userId ?? ''))?.driverId;
        if (_driverId == null) {
          stream = Stream.value(<BookingModel>[]);
        } else {
          stream = _repo.streamBookingsForMonthByDriver(_driverId!, month.year, month.month);
        }
      }

      _monthSub?.cancel();
      _monthSub = stream.listen(
        (bookings) {
          final map = <DateTime, List<BookingModel>>{};

          for (final b in bookings) {
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
          isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Firestore Stream Error: $e');
          if (e is FirebaseException) {
            errorMessage = switch (e.code) {
              'failed-precondition' => 'Konfigurasi database belum lengkap (index).',
              'permission-denied'   => 'Tidak punya akses ke data ini.',
              _ => 'Gagal memuat jadwal.',
            };
          } else {
            errorMessage = 'Gagal memuat jadwal.';
          }
          isLoading = false;
          notifyListeners();
        },
      );
    } catch (e, st) {
      debugPrint('Unexpected: $e\n$st');
      errorMessage = 'Gagal memuat jadwal.';
      isLoading = false;
      notifyListeners();
    }
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
