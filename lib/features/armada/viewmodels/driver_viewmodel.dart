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

  /// Batch: create Auth + users doc + drivers doc
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

      // Create Auth account + users doc
      final now = DateTime.now();
      final userModel = await _authRepo.createUserAccount(
        email: email,
        password: password,
        displayName: name,
      );

      // Create drivers doc
      final driver = DriverModel(
        driverId: '',
        name: name,
        codeId: codeId,
        phone: phone,
        userId: userModel.userId,
        status: DriverStatus.standby,
        createdAt: now,
        updatedAt: now,
      );
      final driverId = await _driverRepo.add(driver);

      // TASK-05: link the new driverId onto the user doc so Firestore security
      // rules can scope this operator's booking reads to their own trips.
      await _authRepo.linkDriverToUser(userModel.userId, driverId);

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
      await _driverRepo.delete(driverId);
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
