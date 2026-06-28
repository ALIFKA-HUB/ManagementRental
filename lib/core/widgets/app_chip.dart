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

  // Warna dinamis berdasarkan status string
  static Color _colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
      case 'standby':
      case 'completed':
      case 'paid':
        return AppColors.success;
      case 'in_use':
      case 'on_trip':
      case 'active':
      case 'dp':
        return AppColors.warning;
      case 'maintenance':
      case 'cancelled':
      case 'unpaid':
        return AppColors.error;
      case 'upcoming':
        return AppColors.primary;
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
