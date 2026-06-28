import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<User> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!;
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> createUserAccount({
    required String email,
    required String password,
    required String displayName,
    String? driverId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final now = DateTime.now();
    final user = UserModel(
      userId: uid,
      email: email,
      displayName: displayName,
      role: UserRole.operator,
      driverId: driverId,
      createdAt: now,
      updatedAt: now,
    );
    await _db.collection('users').doc(uid).set(user.toFirestore());
    return user;
  }
}
