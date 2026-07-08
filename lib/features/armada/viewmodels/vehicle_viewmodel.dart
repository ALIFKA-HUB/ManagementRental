import 'package:flutter/foundation.dart';
import 'package:rentalin/data/models/vehicle_model.dart';
import 'package:rentalin/data/repositories/vehicle_repository.dart';
import 'package:rentalin/data/repositories/booking_repository.dart';
import 'package:rentalin/core/utils/app_error.dart';
import 'package:rentalin/core/utils/connectivity_service.dart';
import 'package:rentalin/core/utils/firebase_extensions.dart';

class VehicleViewModel extends ChangeNotifier {
  final VehicleRepository _vehicleRepo = VehicleRepository();
  final BookingRepository _bookingRepo = BookingRepository();

  List<VehicleModel> _allVehicles = [];
  String _searchQuery = '';
  VehicleCategory? _selectedCategory;

  List<VehicleModel> get vehicles {
    if (_searchQuery.isEmpty && _selectedCategory == null) {
      return _allVehicles;
    }
    return _allVehicles.where((v) {
      final matchesSearch = v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || v.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  String get searchQuery => _searchQuery;
  VehicleCategory? get selectedCategory => _selectedCategory;

  bool get isOriginalListEmpty => _allVehicles.isEmpty;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(VehicleCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadVehicles() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _allVehicles = await _vehicleRepo.getAll().withFirebaseTimeout();
    } catch (e) {
      if (e is AppError) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Gagal memuat data kendaraan.';
      }
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
      if (!ConnectivityService().isOnline) {
        throw AppError('Tidak ada koneksi internet. Data tidak dapat disimpan.');
      }
      final plateExists = await _vehicleRepo.checkPlateExists(plateNumber).withFirebaseTimeout();
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
      await _vehicleRepo.add(vehicle).withFirebaseTimeout();
      await loadVehicles();
      return true;
    } catch (e) {
      if (e is AppError) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Gagal menambah kendaraan.';
      }
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
      if (!ConnectivityService().isOnline) {
        throw AppError('Tidak ada koneksi internet. Data tidak dapat disimpan.');
      }
      final plateExists = await _vehicleRepo.checkPlateExists(
        plateNumber,
        excludeId: vehicle.vehicleId,
      ).withFirebaseTimeout();
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
      await _vehicleRepo.update(updated).withFirebaseTimeout();
      await loadVehicles();
      return true;
    } catch (e) {
      if (e is AppError) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Gagal mengupdate kendaraan.';
      }
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
      if (!ConnectivityService().isOnline) {
        throw AppError('Tidak ada koneksi internet. Data tidak dapat disimpan.');
      }
      final activeBookings = await _bookingRepo.getActiveBookings().withFirebaseTimeout();
      final hasActive = activeBookings.any((b) => b.vehicleId == vehicleId);
      if (hasActive) {
        errorMessage = 'Kendaraan masih memiliki booking aktif.';
        isLoading = false;
        notifyListeners();
        return false;
      }
      await _vehicleRepo.delete(vehicleId).withFirebaseTimeout();
      await loadVehicles();
      return true;
    } catch (e) {
      if (e is AppError) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Gagal menghapus kendaraan.';
      }
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStatus(VehicleModel vehicle) async {
    if (!ConnectivityService().isOnline) {
      errorMessage = 'Tidak ada koneksi internet. Data tidak dapat disimpan.';
      notifyListeners();
      return false;
    }
    final newStatus = vehicle.status == VehicleStatus.ready
        ? VehicleStatus.maintenance
        : VehicleStatus.ready;
    try {
      await _vehicleRepo.updateStatus(vehicle.vehicleId, newStatus).withFirebaseTimeout();
      await loadVehicles();
      return true;
    } catch (e) {
      errorMessage = 'Gagal mengubah status kendaraan.';
      notifyListeners();
      return false;
    }
  }
}
