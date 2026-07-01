import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../firebase_options.dart';

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

  /// Creates a driver's Firebase Auth account WITHOUT signing out the current admin.
  /// Uses a secondary Firebase App instance to isolate the new session.
  Future<UserModel> createUserAccount({
    required String email,
    required String password,
    required String displayName,
    String? driverId,
  }) async {
    // Use a secondary app so admin session is not affected
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondaryApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      // App already exists (e.g. from a previous failed attempt)
      if (e.code == 'duplicate-app') {
        secondaryApp = Firebase.app('secondaryApp');
      } else {
        rethrow;
      }
    }

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;
      // Sign out the secondary session immediately
      await secondaryAuth.signOut();

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
    } finally {
      await secondaryApp.delete();
    }
  }

  /// TASK-05: denormalize the driverId onto the user doc so Firestore security
  /// rules can scope an operator's booking reads to their own assigned trips.
  Future<void> linkDriverToUser(String uid, String driverId) async {
    await _db.collection('users').doc(uid).update({
      'driverId': driverId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
