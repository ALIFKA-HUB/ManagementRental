import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// TASK-03: tunable rental policy stored in Firestore so it can change without
/// an app rebuild. Document path: `settings/rentalPolicy`.
class RentalPolicy {
  /// Minimum turnaround gap (minutes) enforced between two bookings of the same
  /// vehicle/driver — time for cleaning, refuel, inspection, etc.
  final int bufferMinutes;

  const RentalPolicy({required this.bufferMinutes});

  /// Safe default used when the settings doc is missing or unreadable.
  static const fallback = RentalPolicy(bufferMinutes: 0);
}

class SettingsRepository {
  final DocumentReference _doc =
      FirebaseFirestore.instance.collection('settings').doc('rentalPolicy');

  Future<RentalPolicy> getRentalPolicy() async {
    try {
      final snap = await _doc.get();
      final data = snap.data() as Map<String, dynamic>?;
      final mins = (data?['defaultBufferMinutes'] as num?)?.toInt() ?? 0;
      // Clamp to a sane range to avoid a misconfigured value blocking all bookings.
      return RentalPolicy(bufferMinutes: mins.clamp(0, 24 * 60));
    } catch (e) {
      debugPrint('getRentalPolicy failed, using fallback: $e');
      return RentalPolicy.fallback;
    }
  }
}
