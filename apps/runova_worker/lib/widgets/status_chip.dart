import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final RepairStatus status;

  const StatusChip({super.key, required this.status});

  Color get _bgColor {
    switch (status) {
      case RepairStatus.inspected:
        return AppColors.statusInspectedBg;
      case RepairStatus.partBought:
        return AppColors.statusPartBoughtBg;
      case RepairStatus.done:
        return AppColors.statusDoneBg;
      case RepairStatus.delivered:
        return AppColors.statusDeliveredBg;
    }
  }

  Color get _borderColor {
    switch (status) {
      case RepairStatus.inspected:
        return AppColors.statusInspectedBorder;
      case RepairStatus.partBought:
        return AppColors.statusPartBoughtBorder;
      case RepairStatus.done:
        return AppColors.statusDoneBorder;
      case RepairStatus.delivered:
        return AppColors.statusDeliveredBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Text(
        '${status.label} • ${status.labelBengali}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _borderColor,
        ),
      ),
    );
  }
}
