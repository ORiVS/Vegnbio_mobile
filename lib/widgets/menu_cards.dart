import 'package:flutter/material.dart';
import '../models/dish.dart';
import '../theme/app_colors.dart';
import 'dish_avatar.dart';

// --- SmallDishCard (card horizontale 150 x 170 env.) ---
class SmallDishCard extends StatelessWidget {
  final Dish dish;
  final bool unavailable;
  final VoidCallback? onTap;
  const SmallDishCard({
    super.key,
    required this.dish,
    this.unavailable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Hauteur cible ~170 dans la liste horizontale ; on s'assure que l'intérieur ne déborde pas.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/thumbnail de hauteur fixe pour ne pas pousser le texte
            // Ajuste la hauteur (72–88) selon ton design
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F3),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.restaurant, size: 28, color: Colors.black54),
            ),

            const SizedBox(height: 8),

            // Le titre occupe l'espace disponible, se coupe à 2 lignes max
            Expanded(
              child: Text(
                dish.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),

            const SizedBox(height: 6),

            // Ligne bas : prix + badge indispo (pas plus de 1 ligne)
            Row(
              children: [
                Text(
                  _formatPrice(dish.price),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (unavailable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Rupture',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(num p) {
    // Affichage simple ; adapte si tu utilises intl
    return '${p.toStringAsFixed(2)} €';
  }
}

// --- LargeDishRowCard (liste verticale) ---
class LargeDishRowCard extends StatelessWidget {
  final Dish dish;
  final bool unavailable;
  final VoidCallback? onTap;
  const LargeDishRowCard({
    super.key,
    required this.dish,
    this.unavailable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 1))],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visuel fixe pour stabiliser la hauteur
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F3),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.restaurant_menu, size: 24, color: Colors.black54),
            ),
            const SizedBox(width: 12),

            // Zone texte extensible
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre : 1 ligne max pour éviter l’overflow
                  Text(
                    dish.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),

                  // Description : 2 lignes max
                  if ((dish.description ?? '').isNotEmpty)
                    Text(
                      dish.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  const SizedBox(height: 8),

                  // Bas de carte : prix + indispo
                  Row(
                    children: [
                      Text(
                        _formatPrice(dish.price),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      if (unavailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Rupture',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(num p) => '${p.toStringAsFixed(2)} €';
}
