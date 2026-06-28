import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_model.dart';

class DriverRepository {
  final _col = FirebaseFirestore.instance.collection('drivers');

  Future<List<DriverModel>> getAll() async {
    final snap = await _col.orderBy('name').get();
    return snap.docs.map(DriverModel.fromFirestore).toList();
  }

  Future<DriverModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return DriverModel.fromFirestore(doc);
  }

  Future<List<DriverModel>> getStandbyDrivers() async {
    final snap = await _col.where('status', isEqualTo: 'standby').get();
    return snap.docs.map(DriverModel.fromFirestore).toList();
  }

  Future<String> add(DriverModel driver) async {
    final ref = await _col.add(driver.toFirestore());
    return ref.id;
  }

  Future<void> update(DriverModel driver) =>
      _col.doc(driver.driverId).update(driver.toFirestore());

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> updateStatus(String driverId, DriverStatus status) =>
      _col.doc(driverId).update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<bool> checkCodeIdExists(String codeId, {String? excludeId}) async {
    final snap = await _col.where('codeId', isEqualTo: codeId).limit(1).get();
    if (snap.docs.isEmpty) return false;
    if (excludeId != null && snap.docs.first.id == excludeId) return false;
    return true;
  }
}
