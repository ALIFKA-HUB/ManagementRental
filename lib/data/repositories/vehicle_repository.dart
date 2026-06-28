import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';

class VehicleRepository {
  final _col = FirebaseFirestore.instance.collection('vehicles');

  Future<List<VehicleModel>> getAll() async {
    final snap = await _col.orderBy('name').get();
    return snap.docs.map(VehicleModel.fromFirestore).toList();
  }

  Future<VehicleModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return VehicleModel.fromFirestore(doc);
  }

  Future<List<VehicleModel>> getByStatus(VehicleStatus status) async {
    final snap = await _col.where('status', isEqualTo: status.value).get();
    return snap.docs.map(VehicleModel.fromFirestore).toList();
  }

  Future<List<VehicleModel>> getReadyVehicles() => getByStatus(VehicleStatus.ready);

  Future<String> add(VehicleModel vehicle) async {
    final ref = await _col.add(vehicle.toFirestore());
    return ref.id;
  }

  Future<void> update(VehicleModel vehicle) =>
      _col.doc(vehicle.vehicleId).update(vehicle.toFirestore());

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> updateStatus(String vehicleId, VehicleStatus status) =>
      _col.doc(vehicleId).update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<bool> checkPlateExists(String plateNumber, {String? excludeId}) async {
    final snap = await _col.where('plateNumber', isEqualTo: plateNumber).limit(1).get();
    if (snap.docs.isEmpty) return false;
    if (excludeId != null && snap.docs.first.id == excludeId) return false;
    return true;
  }
}
