import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleStatus { ready, inUse, maintenance }

enum VehicleCategory { bus, elf, hiace, mpv, suv, other }

extension VehicleStatusExt on VehicleStatus {
  String get label {
    switch (this) {
      case VehicleStatus.ready: return 'Ready';
      case VehicleStatus.inUse: return 'Sedang Digunakan';
      case VehicleStatus.maintenance: return 'Bengkel';
    }
  }

  String get value {
    switch (this) {
      case VehicleStatus.ready: return 'ready';
      case VehicleStatus.inUse: return 'in_use';
      case VehicleStatus.maintenance: return 'maintenance';
    }
  }
}

extension VehicleCategoryExt on VehicleCategory {
  String get label {
    switch (this) {
      case VehicleCategory.bus: return 'Bus';
      case VehicleCategory.elf: return 'Elf';
      case VehicleCategory.hiace: return 'Hiace';
      case VehicleCategory.mpv: return 'MPV';
      case VehicleCategory.suv: return 'SUV';
      case VehicleCategory.other: return 'Lainnya';
    }
  }

  String get value => name;
}

class VehicleModel {
  final String vehicleId;
  final String name;
  final String plateNumber;
  final VehicleCategory category;
  final VehicleStatus status;
  final String? photoUrl;
  final String? conditionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleModel({
    required this.vehicleId,
    required this.name,
    required this.plateNumber,
    required this.category,
    required this.status,
    this.photoUrl,
    this.conditionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      vehicleId: doc.id,
      name: d['name'] ?? '',
      plateNumber: d['plateNumber'] ?? '',
      category: VehicleCategory.values.firstWhere(
        (e) => e.value == d['category'],
        orElse: () => VehicleCategory.other,
      ),
      status: VehicleStatus.values.firstWhere(
        (e) => e.value == d['status'],
        orElse: () => VehicleStatus.ready,
      ),
      photoUrl: d['photoUrl'],
      conditionNotes: d['conditionNotes'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'plateNumber': plateNumber,
        'category': category.value,
        'status': status.value,
        'photoUrl': photoUrl,
        'conditionNotes': conditionNotes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  VehicleModel copyWith({
    String? name,
    String? plateNumber,
    VehicleCategory? category,
    VehicleStatus? status,
    String? photoUrl,
    String? conditionNotes,
  }) {
    return VehicleModel(
      vehicleId: vehicleId,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      category: category ?? this.category,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      conditionNotes: conditionNotes ?? this.conditionNotes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
