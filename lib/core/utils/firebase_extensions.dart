import 'dart:async';
import 'app_error.dart';

extension FirebaseTimeoutExtension<T> on Future<T> {
  Future<T> withFirebaseTimeout() {
    return timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw AppError('Koneksi timeout');
      },
    );
  }
}
