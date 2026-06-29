import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';
import 'package:rentalin/data/repositories/driver_repository.dart';

class OperatorHomeViewModel extends ChangeNotifier {
  final BookingRepository _bookingRepo = BookingRepository();
  final DriverRepository _driverRepo = DriverRepository();

  // Supir yang terhubung ke user ini (via userId field)
  String? _driverId;

  List<BookingModel> todayBookings = [];
  List<BookingModel> upcomingBookings = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Cari driverId dari userId
      if (_driverId == null) {
        final driver = await _driverRepo.findByUserId(userId);
        _driverId = driver?.driverId;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (_driverId != null) {
        // Booking berdasarkan supir
        final active = await _bookingRepo.getBookingsByDriver(_driverId!);
        todayBookings = active.where((b) {
          final startDay = DateTime(b.startDateTime.year, b.startDateTime.month, b.startDateTime.day);
          return startDay == today;
        }).toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

        upcomingBookings = active.where((b) => b.startDateTime.isAfter(today)).toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      } else {
        // Operator bukan supir → lihat semua jadwal hari ini
        final all = await _bookingRepo.getBookingsForDate(today);
        todayBookings = all
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
        upcomingBookings = [];
      }
    } on FirebaseException catch (e, st) {
      debugPrint('Firestore [${e.code}]: ${e.message}\n$st');
      errorMessage = switch (e.code) {
        'failed-precondition' => 'Konfigurasi database belum lengkap (index).',
        'permission-denied'   => 'Tidak punya akses ke data ini.',
        'unavailable'         => 'Tidak ada koneksi. Coba lagi.',
        _ => 'Gagal memuat data.',
      };
    } catch (e, st) {
      debugPrint('Unexpected: $e\n$st');
      errorMessage = 'Gagal memuat data.';
    }

    isLoading = false;
    notifyListeners();
  }

  bool get isDriver => _driverId != null;
}
