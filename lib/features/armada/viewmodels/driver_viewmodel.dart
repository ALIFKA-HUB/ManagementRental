import 'package:flutter/foundation.dart';
import 'package:rentalin/data/models/driver_model.dart';
import 'package:rentalin/data/repositories/auth_repository.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';
import 'package:rentalin/data/repositories/driver_repository.dart';

class DriverViewModel extends ChangeNotifier {
  final DriverRepository _driverRepo = DriverRepository();
  final BookingRepository _bookingRepo = BookingRepository();
  final AuthRepository _authRepo = AuthRepository();

  List<DriverModel> drivers = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadDrivers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      drivers = await _driverRepo.getAll();
    } catch (_) {
      errorMessage = 'Gagal memuat data supir.';
    }
    isLoading = false;
    notifyListeners();
  }

  /// TASK-08: Create Auth + users doc + drivers doc atomically (single batch,
  /// with compensating Auth cleanup on failure) so no orphan account/doc can
  /// be left behind.
  Future<bool> addDriver({
    required String name,
    required String codeId,
    required String phone,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final codeExists = await _driverRepo.checkCodeIdExists(codeId);
      if (codeExists) {
        errorMessage = 'Kode ID supir sudah digunakan.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Auth account + users doc + drivers doc, all-or-nothing.
      await _authRepo.createDriverAccount(
        name: name,
        codeId: codeId,
        phone: phone,
        email: email,
        password: password,
      );

      await loadDrivers();
      return true;
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Email sudah terdaftar di sistem.';
      } else {
        errorMessage = 'Gagal menambah supir: ${e.toString()}';
      }
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDriver({
    required DriverModel driver,
    required String name,
    required String codeId,
    required String phone,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final codeExists = await _driverRepo.checkCodeIdExists(
        codeId,
        excludeId: driver.driverId,
      );
      if (codeExists) {
        errorMessage = 'Kode ID sudah digunakan supir lain.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      await _driverRepo.update(driver.copyWith(name: name, codeId: codeId, phone: phone));
      await loadDrivers();
      return true;
    } catch (_) {
      errorMessage = 'Gagal mengupdate data supir.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDriver(String driverId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final active = await _bookingRepo.getActiveBookings();
      if (active.any((b) => b.driverId == driverId)) {
        errorMessage = 'Supir masih memiliki booking aktif.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      // TASK-08: resolve the linked userId (prefer the in-memory list, fall
      // back to a fetch) so we can tear down both `drivers` and `users` docs
      // atomically. Removing the users doc locks the account out of the app.
      final linkedUserId = drivers
          .firstWhere(
            (d) => d.driverId == driverId,
            orElse: () => DriverModel(
              driverId: driverId,
              name: '',
              codeId: '',
              phone: '',
              userId: '',
              status: DriverStatus.standby,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .userId;
      final userId = linkedUserId.isNotEmpty
          ? linkedUserId
          : (await _driverRepo.getById(driverId))?.userId ?? '';

      await _authRepo.deleteDriverAccount(driverId: driverId, userId: userId);
      await loadDrivers();
      return true;
    } catch (_) {
      errorMessage = 'Gagal menghapus supir.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
