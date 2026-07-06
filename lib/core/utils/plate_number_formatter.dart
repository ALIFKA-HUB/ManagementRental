import 'package:flutter/services.dart';

class PlateNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 1. Ubah ke uppercase dan hilangkan karakter selain huruf dan angka
    String text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // 2. Terapkan format spasi: [Huruf 1-2] [Angka 1-4] [Huruf 1-3]
    String formatted = '';
    
    // Pisahkan grup huruf pertama
    int i = 0;
    while (i < text.length && RegExp(r'[A-Z]').hasMatch(text[i])) {
      formatted += text[i];
      i++;
      if (i >= 2) break; // Maksimal 2 huruf di depan
    }

    // Pisahkan grup angka
    if (i < text.length) {
      if (formatted.isNotEmpty) formatted += ' ';
      int count = 0;
      while (i < text.length && RegExp(r'[0-9]').hasMatch(text[i])) {
        formatted += text[i];
        i++;
        count++;
        if (count >= 4) break; // Maksimal 4 angka
      }
    }

    // Pisahkan grup huruf terakhir
    if (i < text.length) {
      if (formatted.isNotEmpty && !formatted.endsWith(' ')) formatted += ' ';
      int count = 0;
      while (i < text.length && RegExp(r'[A-Z]').hasMatch(text[i])) {
        formatted += text[i];
        i++;
        count++;
        if (count >= 3) break; // Maksimal 3 huruf di belakang
      }
    }

    // Hitung posisi kursor baru
    int selectionIndex = formatted.length;
    // (Dalam kasus yang lebih kompleks kita bisa menghitung posisi kursor dari oldValue, 
    // namun untuk input mask pendek seperti ini biasanya meletakkan di akhir cukup oke,
    // atau biarkan user hanya ngetik di akhir)

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
