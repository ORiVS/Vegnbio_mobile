// lib/widgets/status_chip.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    Color bg;
    Color fg;

    switch (s) {
      case 'CONFIRMED':
      case 'PUBLISHED':
        bg = kPrimaryGreen.withOpacity(.15); fg = kPrimaryGreenDark; break;
      case 'PENDING':
        bg = Colors.orange.withOpacity(.15); fg = Colors.orange; break;
      case 'FULL':
        bg = Colors.grey.withOpacity(.18); fg = Colors.grey.shade700; break;
      case 'CANCELLED':
        bg = Colors.red.withOpacity(.15); fg = Colors.red; break;
      default:
        bg = Colors.grey.withOpacity(.15); fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
