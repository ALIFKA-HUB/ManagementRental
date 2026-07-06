import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rentalin/core/utils/app_time.dart';
import 'package:rentalin/data/models/booking_log_model.dart';
import 'package:rentalin/data/models/booking_model.dart';
import 'package:rentalin/data/models/driver_model.dart';
import 'package:rentalin/data/models/vehicle_model.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';
import 'package:rentalin/data/repositories/customer_repository.dart';
import 'package:rentalin/data/repositories/driver_repository.dart';
import 'package:rentalin/data/repositories/settings_repository.dart';
import 'package:rentalin/data/repositories/vehicle_repository.dart';
import 'package:rentalin/core/utils/app_error.dart';
import 'package:rentalin/core/utils/connectivity_service.dart';
import 'package:rentalin/core/utils/firebase_extensions.dart';

enum BookingFilter { all, today, thisWeek }
enum HistoryFilter { all, today, thisWeek, thisMonth }

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
  HistoryFilter currentHistoryFilter = HistoryFilter.all;
  bool isLoading = false;
  bool isLoadingHistory = false;
  String? errorMessage;

  /// TASK-10: cursor pagination state for the history list.
  DocumentSnapshot? _historyCursor;
  bool historyHasMore = true;
  bool isLoadingMoreHistory = false;
  static const int _historyPageSize = 20;

  /// TASK-11: free-text search (customer name / plate / driver) over the
  /// already-loaded active bookings — no extra Firestore reads.
  String searchQuery = '';
  
  /// Search query for history bookings.
  String historySearchQuery = '';

  /// Best-effort refresh of the configurable turnaround buffer.
  Future<void> _loadBuffer() async {
    bufferMinutes = (await _settingsRepo.getRentalPolicy()).bufferMinutes;
  }

  bool _isDisposed = false;
  StreamSubscription<List<BookingModel>>? _activeSub;

  @override
  void dispose() {
    _isDisposed = true;
    _activeSub?.cancel();
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> loadActiveBookings() async {
    isLoading = true;
    errorMessage = null;
    _safeNotify();
    try {
      await _loadBuffer();
      await _bookingRepo.syncActiveStatuses().withFirebaseTimeout();
      
      if (_isDisposed) return;

      _activeSub?.cancel();
      _activeSub = _bookingRepo.streamActiveBookings().listen(
        (bookings) {
          activeBookings = bookings;
          _applyFilter();
          isLoading = false;
          _safeNotify();
        },
        onError: (e) {
          if (kDebugMode) debugPrint('Firestore Stream Error: $e');
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
          _safeNotify();
        },
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('Unexpected: $e\n$st');
      errorMessage = 'Gagal memuat booking.';
      isLoading = false;
      _safeNotify();
    }
  }

  void setHistorySearchQuery(String query) {
    if (historySearchQuery == query) return;
    historySearchQuery = query;
    notifyListeners();
  }

  void setHistoryFilter(HistoryFilter filter) {
    if (currentHistoryFilter == filter) return;
    currentHistoryFilter = filter;
    loadHistoryBookings();
  }

  (DateTime?, DateTime?) _getHistoryDateRange() {
    final now = DateTime.now();
    switch (currentHistoryFilter) {
      case HistoryFilter.all:
        return (null, null);
      case HistoryFilter.today:
        return (AppTime.startOfDay(now), AppTime.endOfDay(now));
      case HistoryFilter.thisWeek:
        final start = AppTime.startOfDay(now.subtract(Duration(days: now.weekday - 1)));
        final end = AppTime.endOfDay(start.add(const Duration(days: 6)));
        return (start, end);
      case HistoryFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = AppTime.endOfDay(DateTime(now.year, now.month + 1, 0));
        return (start, end);
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
      final (start, end) = _getHistoryDateRange();
      final page = await _bookingRepo.getCompletedBookings(
        limit: _historyPageSize,
        startDate: start,
        endDate: end,
      ).withFirebaseTimeout();
      historyBookings = page.items;
      _historyCursor = page.lastDoc;
      historyHasMore = page.hasMore;
    } on FirebaseException catch (e, st) {
      if (kDebugMode) debugPrint('Firestore [${e.code}]: ${e.message}\n$st');
      errorMessage = switch (e.code) {
        'failed-precondition' => 'Konfigurasi database belum lengkap (index).',
        'permission-denied'   => 'Tidak punya akses ke data ini.',
        _ => 'Gagal memuat riwayat booking.',
      };
    } catch (e, st) {
      if (kDebugMode) debugPrint('BookingViewModel Unexpected: $e\n$st');
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
      final (start, end) = _getHistoryDateRange();
      final page = await _bookingRepo.getCompletedBookings(
        startAfter: _historyCursor,
        limit: _historyPageSize,
        startDate: start,
        endDate: end,
      ).withFirebaseTimeout();
      historyBookings = [...historyBookings, ...page.items];
      _historyCursor = page.lastDoc ?? _historyCursor;
      historyHasMore = page.hasMore;
    } on FirebaseException catch (e, st) {
      if (kDebugMode) debugPrint('Firestore [${e.code}]: ${e.message}\n$st');
      // Keep what we already have; allow a later retry.
    } catch (e, st) {
      if (kDebugMode) debugPrint('BookingViewModel Unexpected: $e\n$st');
    }
    isLoadingMoreHistory = false;
    notifyListeners();
  }

  /// History bookings filtered by search query
  List<BookingModel> get filteredHistoryBookings {
    if (historySearchQuery.trim().isEmpty) return historyBookings;
    final q = historySearchQuery.trim().toLowerCase();
    return historyBookings.where((b) {
      final matchCust = b.customerName.toLowerCase().contains(q);
      final matchVehicle = b.vehicleName.toLowerCase().contains(q);
      final matchPlate = b.vehiclePlate.toLowerCase().contains(q);
      return matchCust || matchVehicle || matchPlate;
    }).toList();
  }

  Future<void> loadFormData() async {
    try {
      // TASK-01: availability is computed from date-overlap, so the candidate
      // pool is every bookable vehicle (anything not in maintenance) and every
      // driver — not just those whose status flag is currently ready/standby.
      // A vehicle that is out today, or already booked for another date, can
      // still be booked for a non-overlapping range.
      final allVehicles = await _vehicleRepo.getAll().withFirebaseTimeout();
      readyVehicles =
          allVehicles.where((v) => v.status != VehicleStatus.maintenance).toList();
      standbyDrivers = await _driverRepo.getAll().withFirebaseTimeout();
      await _loadBuffer(); // TASK-03: refresh turnaround buffer
      notifyListeners();
    } catch (_) {}
  }

  /// TASK-11: [excludeBookingId] lets the edit form ignore the booking being
  /// edited when computing availability, so its own vehicle/driver stay
  /// selectable.
  List<VehicleModel> getAvailableVehicles(DateTime? start, DateTime? end,
      {String? excludeBookingId}) {
    if (start == null || end == null) return readyVehicles;
    final buffer = Duration(minutes: bufferMinutes);
    return readyVehicles.where((v) {
      final conflict = activeBookings.any((b) =>
        b.bookingId != excludeBookingId &&
        b.vehicleId == v.vehicleId &&
        b.startDateTime.subtract(buffer).isBefore(end) &&
        b.endDateTime.add(buffer).isAfter(start)
      );
      return !conflict;
    }).toList();
  }

  List<DriverModel> getAvailableDrivers(DateTime? start, DateTime? end,
      {String? excludeBookingId}) {
    if (start == null || end == null) return standbyDrivers;
    final buffer = Duration(minutes: bufferMinutes);
    return standbyDrivers.where((d) {
      final conflict = activeBookings.any((b) =>
        b.bookingId != excludeBookingId &&
        b.driverId == d.driverId &&
        b.startDateTime.subtract(buffer).isBefore(end) &&
        b.endDateTime.add(buffer).isAfter(start)
      );
      return !conflict;
    }).toList();
  }

  /// TASK-12: the active booking that makes [vehicleId] unavailable in the
  /// selected [start]..[end] window (respecting the turnaround buffer), or null
  /// if the vehicle is free. Lets the form disable + annotate the option with
  /// the conflicting dates instead of hiding it. Excludes [excludeBookingId]
  /// so an edited booking doesn't clash with itself.
  BookingModel? vehicleConflict(String vehicleId, DateTime? start, DateTime? end,
      {String? excludeBookingId}) {
    if (start == null || end == null) return null;
    final buffer = Duration(minutes: bufferMinutes);
    for (final b in activeBookings) {
      if (b.bookingId == excludeBookingId) continue;
      if (b.vehicleId != vehicleId) continue;
      if (b.startDateTime.subtract(buffer).isBefore(end) &&
          b.endDateTime.add(buffer).isAfter(start)) {
        return b;
      }
    }
    return null;
  }

  /// TASK-12: same as [vehicleConflict] but for a driver.
  BookingModel? driverConflict(String driverId, DateTime? start, DateTime? end,
      {String? excludeBookingId}) {
    if (start == null || end == null) return null;
    final buffer = Duration(minutes: bufferMinutes);
    for (final b in activeBookings) {
      if (b.bookingId == excludeBookingId) continue;
      if (b.driverId != driverId) continue;
      if (b.startDateTime.subtract(buffer).isBefore(end) &&
          b.endDateTime.add(buffer).isAfter(start)) {
        return b;
      }
    }
    return null;
  }

  /// TASK-11: all bookings for one customer (used by the per-customer history
  /// view). Read-only, does not mutate list state.
  Future<List<BookingModel>> getCustomerHistory(String phone) {
    return _bookingRepo.getBookingsByCustomerPhone(phone);
  }

  void filterBookings(BookingFilter filter) {
    currentFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  /// TASK-11: update the text query and re-apply filters (called debounced by
  /// the UI).
  void searchBookings(String query) {
    searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final today = AppTime.wibDay(DateTime.now());
    final endOfWeek = today.add(const Duration(days: 7));

    // 1) time-window chip.
    List<BookingModel> result;
    switch (currentFilter) {
      case BookingFilter.all:
        result = List.from(activeBookings);
        break;
      case BookingFilter.today:
        result = activeBookings.where((b) {
          final startDay = AppTime.wibDay(b.startDateTime);
          final endDay = AppTime.wibDay(b.endDateTime);
          // Booking hari ini jika hari ini berada di antara tanggal mulai dan selesai
          return !today.isBefore(startDay) && !today.isAfter(endDay);
        }).toList();
        break;
      case BookingFilter.thisWeek:
        result = activeBookings.where((b) {
          final startDay = AppTime.wibDay(b.startDateTime);
          final endDay = AppTime.wibDay(b.endDateTime);
          // Booking minggu ini jika rentang booking overlap dengan rentang [today, endOfWeek]
          return !endDay.isBefore(today) && !startDay.isAfter(endOfWeek);
        }).toList();
        break;
    }

    // 2) TASK-11: free-text search across customer, plate and driver.
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((b) =>
        b.customerName.toLowerCase().contains(q) ||
        b.vehiclePlate.toLowerCase().contains(q) ||
        b.vehicleName.toLowerCase().contains(q) ||
        b.driverName.toLowerCase().contains(q) ||
        b.customerPhone.contains(q)
      ).toList();
    }

    filteredBookings = result;
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
      if (!ConnectivityService().isOnline) {
        throw AppError('Tidak ada koneksi internet. Data tidak dapat disimpan.');
      }
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
      ).withFirebaseTimeout();
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

      await _bookingRepo.addWithLog(booking, log).withFirebaseTimeout();
      await _customerRepo.upsertCustomer(customerName, customerPhone).withFirebaseTimeout();
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
      if (kDebugMode) debugPrint('Firestore [${e.code}]: ${e.message}\n$st');
      errorMessage = switch (e.code) {
        'failed-precondition' => 'Konfigurasi database belum lengkap (index).',
        'permission-denied'   => 'Tidak punya akses.',
        _ => 'Gagal membuat booking.',
      };
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e, st) {
      if (kDebugMode) debugPrint('BookingViewModel Unexpected: $e\n$st');
      errorMessage = 'Gagal membuat booking.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// TASK-11: edit an existing booking with full conflict re-validation
  /// (excluding its own id) — no need to cancel + recreate. Mirrors
  /// [createBooking] but calls the repo's updateBooking.
  Future<bool> editBooking({
    required BookingModel existingBooking,
    required String customerName,
    required String customerPhone,
    required VehicleModel vehicle,
    required DriverModel driver,
    required List<String> routes,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required double rentalPrice,
    required PaymentStatus paymentStatus,
    required String uid,
    required String displayName,
    String? notes,
  }) async {
    isLoading = true;
    errorMessage = null;
    _safeNotify();
    try {
      if (!ConnectivityService().isOnline) {
        throw AppError('Tidak ada koneksi internet. Data tidak dapat disimpan.');
      }
      await _loadBuffer();
      final conflict = await _bookingRepo.checkConflict(
        vehicleId: vehicle.vehicleId,
        driverId: driver.driverId,
        start: startDateTime,
        end: endDateTime,
        excludeBookingId: existingBooking.bookingId,
        bufferMinutes: bufferMinutes,
      ).withFirebaseTimeout();
      if (conflict) {
        errorMessage = await _settingsRepo.getRentalPolicy().then((p) => p.bufferMinutes > 0)
            ? 'Jadwal bentrok atau terlalu dekat (jeda min. $bufferMinutes menit) dengan booking lain.'
            : 'Jadwal bentrok dengan booking lain. Periksa kendaraan atau supir.';
        isLoading = false;
        _safeNotify();
        return false;
      }

      final now = DateTime.now();
      final updated = BookingModel(
        bookingId: existingBooking.bookingId,
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
        bookingStatus: existingBooking.bookingStatus,
        notes: notes,
        createdBy: existingBooking.createdBy,
        createdAt: existingBooking.createdAt,
        updatedAt: now,
      );

      final log = BookingLogModel(
        logId: '',
        action: 'Booking diedit',
        performedBy: uid,
        performedByName: displayName,
        timestamp: now,
      );

      await _bookingRepo.updateBooking(updated: updated, log: log).withFirebaseTimeout();
      // TASK-09: the active-bookings stream reflects the update automatically;
      // no manual reload needed (which would re-subscribe the stream).
      isLoading = false;
      _safeNotify();
      return true;
    } on BookingConflictException catch (e) {
      errorMessage = e.message;
      isLoading = false;
      _safeNotify();
      return false;
    } catch (e, st) {
      if (kDebugMode) debugPrint('editBooking error: $e\n$st');
      errorMessage = 'Gagal menyimpan perubahan booking.';
      isLoading = false;
      _safeNotify();
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId, String uid, String displayName) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (!ConnectivityService().isOnline) {
        throw AppError('Tidak ada koneksi internet. Data tidak dapat disimpan.');
      }
      final log = BookingLogModel(
        logId: '',
        action: 'Booking dibatalkan',
        performedBy: uid,
        performedByName: displayName,
        timestamp: DateTime.now(),
      );
      await _bookingRepo.cancelBooking(bookingId: bookingId, log: log).withFirebaseTimeout();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AppError) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Gagal membatalkan booking.';
      }
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
      if (!ConnectivityService().isOnline) {
        throw AppError('Tidak ada koneksi internet. Data tidak dapat disimpan.');
      }
      final log = BookingLogModel(
        logId: '',
        action: 'Booking diselesaikan',
        performedBy: uid,
        performedByName: displayName,
        timestamp: DateTime.now(),
      );
      await _bookingRepo.completeBooking(
        bookingId: bookingId,
        log: log,
      ).withFirebaseTimeout();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AppError) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Gagal menyelesaikan booking.';
      }
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
      if (!ConnectivityService().isOnline) {
        throw AppError('Tidak ada koneksi internet. Data tidak dapat disimpan.');
      }
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
      ).withFirebaseTimeout();
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
      ).withFirebaseTimeout();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('extendBooking error: $e\n$st');
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
      if (!ConnectivityService().isOnline) {
        throw AppError('Tidak ada koneksi internet. Data tidak dapat disimpan.');
      }
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
      ).withFirebaseTimeout();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AppError) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Gagal mengubah status pembayaran.';
      }
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
