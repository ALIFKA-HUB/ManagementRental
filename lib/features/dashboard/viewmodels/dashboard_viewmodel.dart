import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';
import 'package:rentalin/data/repositories/driver_repository.dart';
import 'package:rentalin/data/repositories/vehicle_repository.dart';

class DashboardStats {
  final int totalVehicles;
  final int readyVehicles;
  final int totalDrivers;
  final int standbyDrivers;
  final int activeBookings;
  final int pendingPayment;
  final double todayRevenue;
  final double monthRevenue;

  const DashboardStats({
    required this.totalVehicles,
    required this.readyVehicles,
    required this.totalDrivers,
    required this.standbyDrivers,
    required this.activeBookings,
    required this.pendingPayment,
    required this.todayRevenue,
    required this.monthRevenue,
  });
}

class DashboardViewModel extends ChangeNotifier {
  final BookingRepository _bookingRepo = BookingRepository();
  final VehicleRepository _vehicleRepo = VehicleRepository();
  final DriverRepository _driverRepo = DriverRepository();

  DashboardStats? stats;
  List<BookingModel> upcomingToday = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final results = await Future.wait([
        _vehicleRepo.getAll(),
        _driverRepo.getAll(),
        _bookingRepo.getActiveBookings(),
        _bookingRepo.getBookingsForMonth(now.year, now.month),
        _bookingRepo.getBookingsForDate(today),
      ]);

      final vehicles = results[0] as dynamic;
      final drivers = results[1] as dynamic;
      final active = results[2] as List<BookingModel>;
      final monthly = results[3] as List<BookingModel>;
      final todayBookings = results[4] as List<BookingModel>;

      // Revenue: sum dari booking completed bulan ini
      final monthCompleted = monthly.where((b) => b.bookingStatus == BookingStatus.completed);
      final todayCompleted = todayBookings.where((b) => b.bookingStatus == BookingStatus.completed);

      // Pending payment
      final pending = active.where((b) =>
        b.paymentStatus == PaymentStatus.unpaid ||
        b.paymentStatus == PaymentStatus.dp
      ).length;

      // Upcoming today (belum selesai, mulai hari ini)
      final todayUpcoming = todayBookings.where((b) =>
        b.bookingStatus == BookingStatus.upcoming ||
        b.bookingStatus == BookingStatus.active
      ).toList()
        ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

      stats = DashboardStats(
        totalVehicles: (vehicles as List).length,
        readyVehicles: (vehicles).where((v) => v.status.value == 'ready').length,
        totalDrivers: (drivers as List).length,
        standbyDrivers: (drivers).where((d) => d.status.value == 'standby').length,
        activeBookings: active.length,
        pendingPayment: pending,
        todayRevenue: todayCompleted.fold(0.0, (sum, b) => sum + b.rentalPrice),
        monthRevenue: monthCompleted.fold(0.0, (sum, b) => sum + b.rentalPrice),
      );

      upcomingToday = todayUpcoming;
    } on FirebaseException catch (e, st) {
      debugPrint('Firestore [${e.code}]: ${e.message}\n$st');
      errorMessage = switch (e.code) {
        'failed-precondition' => 'Konfigurasi database belum lengkap (index).',
        'permission-denied'   => 'Tidak punya akses ke data ini.',
        'unavailable'         => 'Tidak ada koneksi. Coba lagi.',
        _ => 'Gagal memuat dashboard.',
      };
    } catch (e, st) {
      debugPrint('Unexpected: $e\n$st');
      errorMessage = 'Gagal memuat dashboard.';
    }

    isLoading = false;
    notifyListeners();
  }
}
