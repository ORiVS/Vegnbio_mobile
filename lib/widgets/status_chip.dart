import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status; // PENDING/CONFIRMED/CANCELLED/FULL/PUBLISHED
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (status) {
      case 'CONFIRMED':
      case 'PUBLISHED':
        bg = Colors.green.shade100;
        break;
      case 'CANCELLED':
        bg = Colors.red.shade100;
        break;
      case 'FULL':
        bg = Colors.orange.shade100;
        break;
      default:
        bg = Colors.grey.shade200;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
