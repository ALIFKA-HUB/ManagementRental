import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle get heading => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get subHeading => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get metric => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get buttonLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );
}
