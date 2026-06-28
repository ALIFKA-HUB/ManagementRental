import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppChip extends StatelessWidget {
  final String label;
  final Color? color;

  const AppChip({
    super.key,
    required this.label,
    this.color,
  });

  // Warna dinamis berdasarkan status string (label dari enum)
  static Color _colorForStatus(String status) {
    switch (status.toLowerCase()) {
      // Kendaraan/Supir: ready/standby = hijau
      case 'ready':
      case 'standby':
        return AppColors.success;
      // Booking selesai/lunas = hijau
      case 'completed':
      case 'selesai':
      case 'paid':
      case 'lunas':
        return AppColors.success;
      // Sedang digunakan / perjalanan / DP = kuning
      case 'in_use':
      case 'sedang digunakan':
      case 'on_trip':
      case 'sedang jalan':
      case 'active':
      case 'aktif':
      case 'dp':
      case 'upcoming':
      case 'akan datang':
        return AppColors.warning;
      // Bengkel / dibatalkan / belum bayar = merah/orange
      case 'maintenance':
      case 'bengkel':
        return AppColors.warning; // orange
      case 'cancelled':
      case 'dibatalkan':
      case 'unpaid':
      case 'belum bayar':
        return AppColors.error;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? _colorForStatus(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
