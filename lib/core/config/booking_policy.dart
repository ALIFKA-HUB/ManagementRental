/// TASK-02: read-time rental policy.
///
/// The app derives booking lifecycle state and late fees from the current
/// time at read-time (no scheduler / Cloud Function required). Single region
/// is assumed (WIB). Tunable here; a later enhancement can source these from
/// a `settings/rentalPolicy` Firestore document.
class BookingPolicy {
  /// Late-return surcharge per *started* hour past `endDateTime`, in Rupiah.
  static const double lateFeePerHour = 50000;
}
