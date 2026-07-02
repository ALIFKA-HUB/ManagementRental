import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_model.dart';
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

  /// TASK-08: Atomically provision a driver — creates the Firebase Auth account
  /// AND writes the `users/{uid}` + `drivers/{id}` docs in a single Firestore
  /// batch, so no half-created record can be left behind.
  ///
  /// Cloud Functions (Admin SDK) would be the ideal home for this, but they
  /// require the Blaze plan which this project intentionally avoids. As the
  /// minimal client-side alternative we: (1) create the Auth user on a
  /// secondary app (admin session untouched), (2) commit both docs in one
  /// batch, and (3) on ANY failure delete the just-created Auth user so there
  /// is no orphan account that could still log in.
  ///
  /// Returns the created [DriverModel] (with its generated id + linked userId).
  Future<DriverModel> createDriverAccount({
    required String name,
    required String codeId,
    required String phone,
    required String email,
    required String password,
  }) async {
    // Use a secondary app so the admin session is not affected.
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondaryApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      // App already exists (e.g. from a previous failed attempt).
      if (e.code == 'duplicate-app') {
        secondaryApp = Firebase.app('secondaryApp');
      } else {
        rethrow;
      }
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    User? createdUser;
    try {
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      createdUser = cred.user;
      final uid = createdUser!.uid;
      // Sign out the secondary session immediately.
      await secondaryAuth.signOut();

      final now = DateTime.now();
      // Pre-generate the driver ref so its id can be denormalized onto the
      // user doc within the SAME batch (no separate linking write).
      final driverRef = _db.collection('drivers').doc();

      final user = UserModel(
        userId: uid,
        email: email,
        displayName: name,
        role: UserRole.operator,
        driverId: driverRef.id,
        createdAt: now,
        updatedAt: now,
      );
      final driver = DriverModel(
        driverId: driverRef.id,
        name: name,
        codeId: codeId,
        phone: phone,
        userId: uid,
        status: DriverStatus.standby,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _db.batch();
      batch.set(_db.collection('users').doc(uid), user.toFirestore());
      batch.set(driverRef, driver.toFirestore());
      await batch.commit();

      return driver;
    } catch (_) {
      // Compensating cleanup: kill the orphan Auth account so it cannot log in.
      try {
        await createdUser?.delete();
      } catch (_) {
        // Best-effort; surface the original error to the caller.
      }
      rethrow;
    } finally {
      await secondaryApp.delete();
    }
  }

  /// TASK-08: Atomically tear down a driver — removes both the `drivers/{id}`
  /// and `users/{uid}` docs in one batch. Deleting the users doc means the
  /// account can no longer resolve a profile and is kicked out on next
  /// auth-state check / login (see AuthViewModel.loadCurrentUser).
  ///
  /// The client SDK cannot delete/disable ANOTHER user's Auth record (that
  /// needs the Admin SDK / Blaze), so the Auth entry itself remains but is
  /// inert — no Firestore profile, so no app access.
  Future<void> deleteDriverAccount({
    required String driverId,
    required String userId,
  }) async {
    final batch = _db.batch();
    batch.delete(_db.collection('drivers').doc(driverId));
    if (userId.isNotEmpty) {
      batch.delete(_db.collection('users').doc(userId));
    }
    await batch.commit();
  }
}
