import 'package:flutter/material.dart';
import '../models/dish.dart';
import '../theme/app_colors.dart';
import '../widgets/allergen_chip.dart';

class DishTile extends StatelessWidget {
  final Dish dish;
  final bool unavailable;
  final VoidCallback? onTap;
  const DishTile({super.key, required this.dish, this.unavailable = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Opacity(
      opacity: unavailable ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(dish.name, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('${dish.price.toStringAsFixed(2)} €',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: -6,
            children: [
              if (dish.isVegan)
                Chip(label: const Text('Vegan', style: TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFFEFF6F3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide.none,
                ),
              ...dish.allergens.map((a) => AllergenChip(a)),
            ],
          ),
          if (unavailable) ...[
            const SizedBox(height: 6),
            Text('Indisponible aujourd’hui', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: content,
        ),
      ),
    );
  }
}
