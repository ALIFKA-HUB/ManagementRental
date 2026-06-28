import 'package:flutter/foundation.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';

class ScheduleViewModel extends ChangeNotifier {
  final BookingRepository _repo = BookingRepository();

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
      final bookings = await _repo.getBookingsForMonth(month.year, month.month);
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
    } catch (_) {
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

  DateTime _normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
