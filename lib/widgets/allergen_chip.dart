import 'package:flutter/material.dart';
import '../models/dish.dart';
import '../theme/app_colors.dart';

class AllergenChip extends StatelessWidget {
  final AllergenRef a;
  const AllergenChip(this.a, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(a.label, style: const TextStyle(fontSize: 12)),
      backgroundColor: kChipBg,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
