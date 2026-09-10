import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';

class RoleMeta {
  final String label;
  final IconData icon;
  final Color color;

  const RoleMeta(this.label, this.icon, this.color);
}

RoleMeta roleMeta(UserRole role) {
  switch (role) {
    case UserRole.resident:
      return const RoleMeta('Resident', Icons.home_rounded, AppColors.success);
    case UserRole.business:
      return const RoleMeta('Business', Icons.storefront_rounded, AppColors.warning);
    case UserRole.collector:
      return const RoleMeta('Collector', Icons.local_shipping_rounded, AppColors.info);
    case UserRole.recycler:
      return const RoleMeta('Recycler', Icons.recycling, AppColors.primary);
    case UserRole.authority:
      return const RoleMeta('Authority', Icons.account_balance_rounded, AppColors.accent);
    case UserRole.administrator:
      return const RoleMeta('Administrator', Icons.shield_rounded, AppColors.danger);
  }
}