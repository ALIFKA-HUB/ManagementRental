import 'package:flutter/foundation.dart';
import 'package:rentalin/data/models/booking_log_model.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/data/models/driver_model.dart';
import 'package:rentalin/data/models/vehicle_model.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';
import 'package:rentalin/data/repositories/customer_repository.dart';
import 'package:rentalin/data/repositories/driver_repository.dart';
import 'package:rentalin/data/repositories/vehicle_repository.dart';

enum BookingFilter { all, today, thisWeek }

class BookingViewModel extends ChangeNotifier {
  final BookingRepository _bookingRepo = BookingRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  final VehicleRepository _vehicleRepo = VehicleRepository();
  final DriverRepository _driverRepo = DriverRepository();

  List<BookingModel> activeBookings = [];
  List<BookingModel> filteredBookings = [];
  List<BookingModel> historyBookings = [];
  List<VehicleModel> readyVehicles = [];
  List<DriverModel> standbyDrivers = [];

  BookingFilter currentFilter = BookingFilter.all;
  bool isLoading = false;
  bool isLoadingHistory = false;
  String? errorMessage;

  Future<void> loadActiveBookings() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      activeBookings = await _bookingRepo.getActiveBookings();
      _applyFilter();
    } catch (_) {
      errorMessage = 'Gagal memuat booking.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadHistoryBookings() async {
    isLoadingHistory = true;
    notifyListeners();
    try {
      historyBookings = await _bookingRepo.getCompletedBookings();
    } catch (_) {
      errorMessage = 'Gagal memuat riwayat booking.';
    }
    isLoadingHistory = false;
    notifyListeners();
  }

  Future<void> loadFormData() async {
    try {
      readyVehicles = await _vehicleRepo.getReadyVehicles();
      standbyDrivers = await _driverRepo.getStandbyDrivers();
      notifyListeners();
    } catch (_) {}
  }

  void filterBookings(BookingFilter filter) {
    currentFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));

    switch (currentFilter) {
      case BookingFilter.all:
        filteredBookings = List.from(activeBookings);
        break;
      case BookingFilter.today:
        filteredBookings = activeBookings.where((b) {
          final start = DateTime(b.startDateTime.year, b.startDateTime.month, b.startDateTime.day);
          return start == today;
        }).toList();
        break;
      case BookingFilter.thisWeek:
        filteredBookings = activeBookings.where((b) =>
          b.startDateTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
          b.startDateTime.isBefore(endOfWeek)
        ).toList();
        break;
    }
  }

  Future<bool> createBooking({
    required String customerName,
    required String customerPhone,
    required VehicleModel vehicle,
    required DriverModel driver,
    required List<String> routes,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required double rentalPrice,
    required PaymentStatus paymentStatus,
    required String createdBy,
    required String createdByName,
    String? notes,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Cek bentrok
      final conflict = await _bookingRepo.checkConflict(
        vehicleId: vehicle.vehicleId,
        driverId: driver.driverId,
        start: startDateTime,
        end: endDateTime,
      );
      if (conflict) {
        errorMessage = 'Jadwal bentrok dengan booking lain. Periksa kendaraan atau supir.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final booking = BookingModel(
        bookingId: '',
        customerName: customerName,
        customerPhone: customerPhone,
        vehicleId: vehicle.vehicleId,
        vehicleName: vehicle.name,
        vehiclePlate: vehicle.plateNumber,
        driverId: driver.driverId,
        driverName: driver.name,
        routes: routes,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        rentalPrice: rentalPrice,
        paymentStatus: paymentStatus,
        bookingStatus: BookingStatus.upcoming,
        notes: notes,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      final log = BookingLogModel(
        logId: '',
        action: 'Booking dibuat',
        performedBy: createdBy,
        performedByName: createdByName,
        timestamp: now,
      );

      await _bookingRepo.addWithLog(booking, log);
      await _customerRepo.upsertCustomer(customerName, customerPhone);
      await loadActiveBookings();
      return true;
    } catch (_) {
      errorMessage = 'Gagal membuat booking.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId, String uid, String displayName) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final log = BookingLogModel(
        logId: '',
        action: 'Booking dibatalkan',
        performedBy: uid,
        performedByName: displayName,
        timestamp: DateTime.now(),
      );
      await _bookingRepo.cancelBooking(bookingId: bookingId, log: log);
      await loadActiveBookings();
      return true;
    } catch (_) {
      errorMessage = 'Gagal membatalkan booking.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeBooking(String bookingId, String uid, String displayName) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final log = BookingLogModel(
        logId: '',
        action: 'Booking diselesaikan',
        performedBy: uid,
        performedByName: displayName,
        timestamp: DateTime.now(),
      );
      await _bookingRepo.completeBooking(bookingId: bookingId, log: log);
      await loadActiveBookings();
      return true;
    } catch (_) {
      errorMessage = 'Gagal menyelesaikan booking.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> extendBooking({
    required String bookingId,
    required DateTime newEnd,
    required double extraPrice,
    required String uid,
    required String displayName,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final log = BookingLogModel(
        logId: '',
        action: 'Booking diperpanjang',
        performedBy: uid,
        performedByName: displayName,
        note: 'Hingga ${newEnd.toIso8601String()}. Tambahan Rp ${extraPrice.toStringAsFixed(0)}',
        timestamp: DateTime.now(),
      );
      await _bookingRepo.extendBooking(
        bookingId: bookingId,
        newEnd: newEnd,
        extraPrice: extraPrice,
        log: log,
      );
      await loadActiveBookings();
      return true;
    } catch (_) {
      errorMessage = 'Gagal memperpanjang booking.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePaymentStatus({
    required String bookingId,
    required PaymentStatus newStatus,
    required String uid,
    required String displayName,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final log = BookingLogModel(
        logId: '',
        action: 'Status bayar diubah ke ${newStatus.label}',
        performedBy: uid,
        performedByName: displayName,
        timestamp: DateTime.now(),
      );
      await _bookingRepo.updatePaymentStatus(
        bookingId: bookingId,
        newStatus: newStatus,
        log: log,
      );
      await loadActiveBookings();
      return true;
    } catch (_) {
      errorMessage = 'Gagal mengubah status pembayaran.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
