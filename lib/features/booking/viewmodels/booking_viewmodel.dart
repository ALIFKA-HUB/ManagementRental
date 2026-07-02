import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rentalin/data/models/booking_log_model.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/data/models/driver_model.dart';
import 'package:rentalin/data/models/vehicle_model.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';
import 'package:rentalin/data/repositories/customer_repository.dart';
import 'package:rentalin/data/repositories/driver_repository.dart';
import 'package:rentalin/data/repositories/settings_repository.dart';
import 'package:rentalin/data/repositories/vehicle_repository.dart';

enum BookingFilter { all, today, thisWeek }

class BookingViewModel extends ChangeNotifier {
  final BookingRepository _bookingRepo = BookingRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  final VehicleRepository _vehicleRepo = VehicleRepository();
  final DriverRepository _driverRepo = DriverRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  List<BookingModel> activeBookings = [];
  List<BookingModel> filteredBookings = [];
  List<BookingModel> historyBookings = [];
  List<VehicleModel> readyVehicles = [];
  List<DriverModel> standbyDrivers = [];

  /// TASK-03: turnaround buffer (minutes) loaded from settings/rentalPolicy.
  int bufferMinutes = 0;

  BookingFilter currentFilter = BookingFilter.all;
  bool isLoading = false;
  bool isLoadingHistory = false;
  String? errorMessage;

  /// TASK-10: cursor pagination state for the history list.
  DocumentSnapshot? _historyCursor;
  bool historyHasMore = true;
  bool isLoadingMoreHistory = false;
  static const int _historyPageSize = 20;

  /// Best-effort refresh of the configurable turnaround buffer.
  Future<void> _loadBuffer() async {
    bufferMinutes = (await _settingsRepo.getRentalPolicy()).bufferMinutes;
  }

  StreamSubscription<List<BookingModel>>? _activeSub;

  @override
  void dispose() {
    _activeSub?.cancel();
    super.dispose();
  }

  Future<void> loadActiveBookings() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _loadBuffer();
      
      _activeSub?.cancel();
      _activeSub = _bookingRepo.streamActiveBookings().listen(
        (bookings) {
          activeBookings = bookings;
          _applyFilter();
          isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Firestore Stream Error: $e');
          if (e is FirebaseException) {
            errorMessage = switch (e.code) {
              'failed-precondition' => 'Konfigurasi database belum lengkap (index).',
              'permission-denied'   => 'Tidak punya akses ke data ini.',
              'unavailable'         => 'Tidak ada koneksi. Coba lagi.',
              _ => 'Gagal memuat booking.',
            };
          } else {
            errorMessage = 'Gagal memuat booking.';
          }
          isLoading = false;
          notifyListeners();
        },
      );
    } catch (e, st) {
      debugPrint('Unexpected: $e\n$st');
      errorMessage = 'Gagal memuat booking.';
      isLoading = false;
      notifyListeners();
    }
  }

  /// TASK-10: (re)load the first page of history. Resets the cursor so this
  /// doubles as pull-to-refresh.
  Future<void> loadHistoryBookings() async {
    isLoadingHistory = true;
    _historyCursor = null;
    historyHasMore = true;
    notifyListeners();
    try {
      final page = await _bookingRepo.getCompletedBookings(limit: _historyPageSize);
      historyBookings = page.items;
      _historyCursor = page.lastDoc;
      historyHasMore = page.hasMore;
    } on FirebaseException catch (e, st) {
      debugPrint('Firestore [${e.code}]: ${e.message}\n$st');
      errorMessage = switch (e.code) {
        'failed-precondition' => 'Konfigurasi database belum lengkap (index).',
        'permission-denied'   => 'Tidak punya akses ke data ini.',
        _ => 'Gagal memuat riwayat booking.',
      };
    } catch (e, st) {
      debugPrint('Unexpected: $e\n$st');
      errorMessage = 'Gagal memuat riwayat booking.';
    }
    isLoadingHistory = false;
    notifyListeners();
  }

  /// TASK-10: fetch the next page and APPEND it. No-op while a page is already
  /// in flight, or once the end has been reached.
  Future<void> loadMoreHistory() async {
    if (isLoadingMoreHistory || !historyHasMore || _historyCursor == null) return;
    isLoadingMoreHistory = true;
    notifyListeners();
    try {
      final page = await _bookingRepo.getCompletedBookings(
        startAfter: _historyCursor,
        limit: _historyPageSize,
      );
      historyBookings = [...historyBookings, ...page.items];
      _historyCursor = page.lastDoc ?? _historyCursor;
      historyHasMore = page.hasMore;
    } on FirebaseException catch (e, st) {
      debugPrint('Firestore [${e.code}]: ${e.message}\n$st');
      // Keep what we already have; allow a later retry.
    } catch (e, st) {
      debugPrint('Unexpected: $e\n$st');
    }
    isLoadingMoreHistory = false;
    notifyListeners();
  }

  Future<void> loadFormData() async {
    try {
      // TASK-01: availability is computed from date-overlap, so the candidate
      // pool is every bookable vehicle (anything not in maintenance) and every
      // driver — not just those whose status flag is currently ready/standby.
      // A vehicle that is out today, or already booked for another date, can
      // still be booked for a non-overlapping range.
      final allVehicles = await _vehicleRepo.getAll();
      readyVehicles =
          allVehicles.where((v) => v.status != VehicleStatus.maintenance).toList();
      standbyDrivers = await _driverRepo.getAll();
      await _loadBuffer(); // TASK-03: refresh turnaround buffer
      notifyListeners();
    } catch (_) {}
  }

  List<VehicleModel> getAvailableVehicles(DateTime? start, DateTime? end) {
    if (start == null || end == null) return readyVehicles;
    final buffer = Duration(minutes: bufferMinutes);
    return readyVehicles.where((v) {
      final conflict = activeBookings.any((b) =>
        b.vehicleId == v.vehicleId &&
        b.startDateTime.subtract(buffer).isBefore(end) &&
        b.endDateTime.add(buffer).isAfter(start)
      );
      return !conflict;
    }).toList();
  }

  List<DriverModel> getAvailableDrivers(DateTime? start, DateTime? end) {
    if (start == null || end == null) return standbyDrivers;
    final buffer = Duration(minutes: bufferMinutes);
    return standbyDrivers.where((d) {
      final conflict = activeBookings.any((b) =>
        b.driverId == d.driverId &&
        b.startDateTime.subtract(buffer).isBefore(end) &&
        b.endDateTime.add(buffer).isAfter(start)
      );
      return !conflict;
    }).toList();
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
      // M-2: Validate duration
      if (!endDateTime.isAfter(startDateTime)) {
        errorMessage = 'Waktu selesai harus setelah waktu mulai.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Cek bentrok (termasuk jeda turnaround / buffer antar booking)
      await _loadBuffer();
      final conflict = await _bookingRepo.checkConflict(
        vehicleId: vehicle.vehicleId,
        driverId: driver.driverId,
        start: startDateTime,
        end: endDateTime,
        bufferMinutes: bufferMinutes,
      );
      if (conflict) {
        errorMessage = bufferMinutes > 0
            ? 'Jadwal bentrok atau terlalu dekat (jeda min. $bufferMinutes menit) dengan booking lain.'
            : 'Jadwal bentrok dengan booking lain. Periksa kendaraan atau supir.';
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
      isLoading = false;
      notifyListeners();
      return true;
    } on BookingConflictException catch (e) {
      // M-1: transaction detected resource grabbed by another admin
      errorMessage = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseException catch (e, st) {
      debugPrint('Firestore [${e.code}]: ${e.message}\n$st');
      errorMessage = switch (e.code) {
        'failed-precondition' => 'Konfigurasi database belum lengkap (index).',
        'permission-denied'   => 'Tidak punya akses.',
        _ => 'Gagal membuat booking.',
      };
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e, st) {
      debugPrint('Unexpected: $e\n$st');
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
      isLoading = false;
      notifyListeners();
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
      // TASK-02: if the booking is overdue, charge an automatic late fee and
      // record it in the activity log alongside the completion.
      BookingModel? booking;
      for (final b in activeBookings) {
        if (b.bookingId == bookingId) { booking = b; break; }
      }
      final lateFee = booking?.lateFee ?? 0;
      final overdueHours = booking?.overdueHours ?? 0;
      final note = lateFee > 0
          ? 'Terlambat $overdueHours jam. Denda Rp ${lateFee.toStringAsFixed(0)}'
          : null;

      final log = BookingLogModel(
        logId: '',
        action: 'Booking diselesaikan',
        performedBy: uid,
        performedByName: displayName,
        note: note,
        timestamp: DateTime.now(),
      );
      await _bookingRepo.completeBooking(
        bookingId: bookingId,
        log: log,
        lateFee: lateFee,
      );
      isLoading = false;
      notifyListeners();
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
      // M-1: conflict check for extend window before committing
      final original = activeBookings.firstWhere(
        (b) => b.bookingId == bookingId,
        orElse: () => throw StateError('Booking not found in active list'),
      );
      // Validate newEnd is strictly after current end (M-4 time picker can still pick same day earlier time)
      if (!newEnd.isAfter(original.endDateTime)) {
        errorMessage = 'Waktu selesai baru harus setelah waktu selesai saat ini.';
        isLoading = false;
        notifyListeners();
        return false;
      }
      await _loadBuffer();
      final conflict = await _bookingRepo.checkConflict(
        vehicleId: original.vehicleId,
        driverId: original.driverId,
        start: original.startDateTime,
        end: newEnd,
        excludeBookingId: bookingId,
        bufferMinutes: bufferMinutes,
      );
      if (conflict) {
        errorMessage = 'Perpanjangan bentrok dengan booking lain.';
        isLoading = false;
        notifyListeners();
        return false;
      }
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
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('extendBooking error: $e\n$st');
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
      isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Gagal mengubah status pembayaran.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
