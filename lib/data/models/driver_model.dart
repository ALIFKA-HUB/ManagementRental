import 'package:cloud_firestore/cloud_firestore.dart';

enum DriverStatus { standby, onTrip }

extension DriverStatusExt on DriverStatus {
  String get label => this == DriverStatus.standby ? 'Standby' : 'Sedang Jalan';
  String get value => this == DriverStatus.standby ? 'standby' : 'on_trip';
}

class DriverModel {
  final String driverId;
  final String name;
  final String codeId;
  final String phone;
  final String userId;
  final DriverStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverModel({
    required this.driverId,
    required this.name,
    required this.codeId,
    required this.phone,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DriverModel(
      driverId: doc.id,
      name: d['name'] ?? '',
      codeId: d['codeId'] ?? '',
      phone: d['phone'] ?? '',
      userId: d['userId'] ?? '',
      status: d['status'] == 'on_trip' ? DriverStatus.onTrip : DriverStatus.standby,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'codeId': codeId,
        'phone': phone,
        'userId': userId,
        'status': status.value,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  DriverModel copyWith({String? name, String? codeId, String? phone, DriverStatus? status}) {
    return DriverModel(
      driverId: driverId,
      name: name ?? this.name,
      codeId: codeId ?? this.codeId,
      phone: phone ?? this.phone,
      userId: userId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
