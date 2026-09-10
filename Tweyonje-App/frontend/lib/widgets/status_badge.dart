import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'COLLECTED':
      case 'PAID':
      case 'SUCCESSFUL':
        bg = AppColors.successLight;
        fg = AppColors.successDark;
        break;
      case 'IN_PROGRESS':
      case 'EN_ROUTE':
      case 'ASSIGNED':
      case 'SCHEDULED':
        bg = AppColors.infoLight;
        fg = AppColors.infoDark;
        break;
      case 'PENDING':
      case 'UNPAID':
        bg = AppColors.warningLight;
        fg = AppColors.warningDark;
        break;
      case 'CANCELLED':
      case 'REJECTED':
      case 'FAILED':
        bg = AppColors.dangerLight;
        fg = AppColors.dangerDark;
        break;
      default:
        bg = AppColors.backgroundSecondary;
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: fontSize ?? 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
