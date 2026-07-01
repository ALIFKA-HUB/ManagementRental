import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppButtonStyle { primary, secondary }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final childWidget = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    Widget button;
    if (style == AppButtonStyle.primary) {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: childWidget,
      );
    } else {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: childWidget,
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: button,
    );
  }
}
