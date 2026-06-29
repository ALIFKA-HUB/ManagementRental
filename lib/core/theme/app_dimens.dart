/// Skala spacing & radius konsisten untuk seluruh app (Flat & Airy).
/// Pakai token ini, hindari angka magic di tiap widget.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  static const double chip = 100; // pill kecil utk lencana
  static const double button = 100; // pill-shape membulat sempurna
  static const double input = 16;
  static const double card = 16; // diturunkan lagi agar lebih proporsional
  static const double sheet = 24;
}
