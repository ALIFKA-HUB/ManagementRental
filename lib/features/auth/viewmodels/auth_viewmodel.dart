import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rentalin/data/models/user_model.dart';
import 'package:rentalin/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  bool isLoading = false;
  String? errorMessage;
  UserModel? currentUser;

  Stream<User?> get authStateChanges => _repo.authStateChanges;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _repo.signIn(email.trim(), password);
      final userModel = await _repo.getUserModel(user.uid);

      if (userModel == null) {
        errorMessage = 'Akun tidak ditemukan di sistem.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      currentUser = userModel;
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapFirebaseError(e.code);
      isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Terjadi kesalahan. Coba lagi.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadCurrentUser(String uid) async {
    currentUser = await _repo.getUserModel(uid);
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.signOut();
    currentUser = null;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      default:
        return 'Login gagal. Coba lagi.';
    }
  }
}
