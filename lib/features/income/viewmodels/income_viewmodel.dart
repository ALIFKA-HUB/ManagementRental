import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';

enum IncomeFilter { today, thisWeek, thisMonth, threeMonths, custom }

class DailyRevenue {
  final DateTime date;
  final double amount;
  DailyRevenue({required this.date, required this.amount});
}

class IncomeViewModel extends ChangeNotifier {
  final BookingRepository _repo = BookingRepository();

  IncomeFilter currentFilter = IncomeFilter.thisMonth;
  DateTime? customFrom;
  DateTime? customTo;

  List<BookingModel> paidBookings = [];
  List<DailyRevenue> dailyRevenues = [];
  double totalRevenue = 0;
  double avgPerDay = 0;
  int bookingCount = 0;

  bool isLoading = false;
  String? errorMessage;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  DateTimeRange get activeRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (currentFilter) {
      case IncomeFilter.today:
        return DateTimeRange(start: today, end: today.add(const Duration(days: 1)));
      case IncomeFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: weekStart, end: today.add(const Duration(days: 1)));
      case IncomeFilter.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: today.add(const Duration(days: 1)),
        );
      case IncomeFilter.threeMonths:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: today.add(const Duration(days: 1)),
        );
      case IncomeFilter.custom:
        return DateTimeRange(
          start: customFrom ?? today,
          end: (customTo ?? today).add(const Duration(days: 1)),
        );
    }
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    _safeNotify();

    try {
      final range = activeRange;
      final bookings = await _repo.getBookingsInRange(range.start, range.end);

      if (_isDisposed) return;

      // Filter hanya yang sudah paid dan status completed
      paidBookings = bookings
          .where((b) =>
              b.bookingStatus == BookingStatus.completed &&
              (b.paymentStatus == PaymentStatus.paid ||
                  b.paymentStatus == PaymentStatus.dp))
          .toList()
        ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));

      // Aggregate per hari
      final Map<DateTime, double> byDay = {};
      for (final b in paidBookings) {
        final day = DateTime(
            b.startDateTime.year, b.startDateTime.month, b.startDateTime.day);
        byDay[day] = (byDay[day] ?? 0) + b.rentalPrice;
      }

      // Fill all days in range with 0 if no revenue
      final days = range.end.difference(range.start).inDays;
      dailyRevenues = List.generate(days, (i) {
        final d = DateTime(
          range.start.year,
          range.start.month,
          range.start.day + i,
        );
        return DailyRevenue(date: d, amount: byDay[d] ?? 0);
      });

      totalRevenue = paidBookings.fold(0, (s, b) => s + b.rentalPrice);
      bookingCount = paidBookings.length;
      final daysWithData = days > 0 ? days : 1;
      avgPerDay = totalRevenue / daysWithData;
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('IncomeViewModel: ${e.code} ${e.message}');
      errorMessage = 'Gagal memuat data pemasukan.';
    } catch (e) {
      if (kDebugMode) debugPrint('IncomeViewModel: $e');
      errorMessage = 'Gagal memuat data pemasukan.';
    }

    isLoading = false;
    _safeNotify();
  }

  Future<void> setFilter(IncomeFilter filter) async {
    currentFilter = filter;
    await load();
  }

  Future<void> setCustomRange(DateTime from, DateTime to) async {
    currentFilter = IncomeFilter.custom;
    customFrom = from;
    customTo = to;
    await load();
  }
}
