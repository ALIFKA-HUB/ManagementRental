import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, operator }

class UserModel {
  final String userId;
  final String email;
  final String displayName;
  final UserRole role;
  final String? photoUrl;
  final String? driverId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.driverId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] == 'admin' ? UserRole.admin : UserRole.operator,
      photoUrl: data['photoUrl'],
      driverId: data['driverId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role == UserRole.admin ? 'admin' : 'operator',
      'photoUrl': photoUrl,
      'driverId': driverId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isAdmin => role == UserRole.admin;
}
