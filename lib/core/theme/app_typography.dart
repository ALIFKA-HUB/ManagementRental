import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle get heading => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get subHeading => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get metric => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get buttonLabel => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );
}
