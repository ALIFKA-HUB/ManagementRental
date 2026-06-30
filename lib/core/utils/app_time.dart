/// TASK-04: timezone normalization helpers.
///
/// The business operates in a single region — Western Indonesia Time (WIB,
/// UTC+7, no DST). Firestore stores each booking as an absolute instant
/// (`Timestamp`), but day-bucketing for the calendar must be done in the
/// business timezone so a booking at e.g. 23:30 lands on the correct calendar
/// day regardless of the device's local timezone.
class AppTime {
  /// WIB offset from UTC. Indonesia western time has no daylight saving.
  static const Duration wibOffset = Duration(hours: 7);

  /// The WIB calendar day (year/month/day at 00:00, tz-naive) of an instant.
  ///
  /// Applying this to both the stored booking instants and the calendar's day
  /// cells keeps bucketing consistent across devices in any timezone.
  static DateTime wibDay(DateTime dt) {
    final w = dt.toUtc().add(wibOffset);
    return DateTime(w.year, w.month, w.day);
  }
}
