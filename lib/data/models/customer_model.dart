import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String customerId;
  final String name;
  final String phone;
  final int bookingCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerModel({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.bookingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      customerId: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      bookingCount: d['bookingCount'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'bookingCount': bookingCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
