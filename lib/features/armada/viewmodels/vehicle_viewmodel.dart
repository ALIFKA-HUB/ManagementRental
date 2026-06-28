import 'package:flutter/foundation.dart';
import 'package:rentalin/data/models/vehicle_model.dart';
import 'package:rentalin/data/repositories/vehicle_repository.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';

class VehicleViewModel extends ChangeNotifier {
  final VehicleRepository _vehicleRepo = VehicleRepository();
  final BookingRepository _bookingRepo = BookingRepository();

  List<VehicleModel> vehicles = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadVehicles() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      vehicles = await _vehicleRepo.getAll();
    } catch (e) {
      errorMessage = 'Gagal memuat data kendaraan.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> addVehicle({
    required String name,
    required String plateNumber,
    required VehicleCategory category,
    String? conditionNotes,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final plateExists = await _vehicleRepo.checkPlateExists(plateNumber);
      if (plateExists) {
        errorMessage = 'Plat nomor sudah terdaftar.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final vehicle = VehicleModel(
        vehicleId: '',
        name: name,
        plateNumber: plateNumber.toUpperCase(),
        category: category,
        status: VehicleStatus.ready,
        photoUrl: null,
        conditionNotes: conditionNotes,
        createdAt: now,
        updatedAt: now,
      );
      await _vehicleRepo.add(vehicle);
      await loadVehicles();
      return true;
    } catch (e) {
      errorMessage = 'Gagal menambah kendaraan.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVehicle({
    required VehicleModel vehicle,
    required String name,
    required String plateNumber,
    required VehicleCategory category,
    String? conditionNotes,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final plateExists = await _vehicleRepo.checkPlateExists(
        plateNumber,
        excludeId: vehicle.vehicleId,
      );
      if (plateExists) {
        errorMessage = 'Plat nomor sudah terdaftar.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      final updated = vehicle.copyWith(
        name: name,
        plateNumber: plateNumber.toUpperCase(),
        category: category,
        conditionNotes: conditionNotes,
      );
      await _vehicleRepo.update(updated);
      await loadVehicles();
      return true;
    } catch (e) {
      errorMessage = 'Gagal mengupdate kendaraan.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final activeBookings = await _bookingRepo.getActiveBookings();
      final hasActive = activeBookings.any((b) => b.vehicleId == vehicleId);
      if (hasActive) {
        errorMessage = 'Kendaraan masih memiliki booking aktif.';
        isLoading = false;
        notifyListeners();
        return false;
      }
      await _vehicleRepo.delete(vehicleId);
      await loadVehicles();
      return true;
    } catch (e) {
      errorMessage = 'Gagal menghapus kendaraan.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleStatus(VehicleModel vehicle) async {
    final newStatus = vehicle.status == VehicleStatus.ready
        ? VehicleStatus.maintenance
        : VehicleStatus.ready;
    await _vehicleRepo.updateStatus(vehicle.vehicleId, newStatus);
    await loadVehicles();
  }
}
