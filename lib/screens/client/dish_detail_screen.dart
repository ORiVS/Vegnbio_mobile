import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dish.dart';
import '../../theme/app_colors.dart';
import '../../widgets/allergen_chip.dart';
import '../../widgets/dish_avatar.dart';
import '../../providers/menu_providers.dart';
import '../../core/api_service.dart';
import '../../core/api_paths.dart';

class DishDetailScreen extends ConsumerWidget {
  static const route = '/c/dish';
  const DishDetailScreen({super.key});

  String _hmNow() {
    final n = DateTime.now();
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(n.hour)}:${two(n.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final Dish dish = args['dish'] as Dish;
    final int restaurantId = (args['restaurantId'] as num).toInt();
    final String date = args['date'] as String;

    final avail = ref.watch(dishAvailableTodayProvider(
      (restaurantId: restaurantId, dishId: dish.id, date: date),
    ));

    // Bouton actif seulement si dispo connue et ok
    final canAdd = avail.maybeWhen(data: (ok) => ok, orElse: () => false);

    Future<void> _addToCart() async {
      try {
        await ApiService.instance.dio.post(ApiPaths.cart, data: {
          'external_item_id': 'DISH-${dish.id}',  // identifiant snapshot
          'name': dish.name,
          'unit_price': dish.price,               // double -> DRF Decimal ok
          'quantity': 1,                          // quantité par défaut
        });
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajouté au panier')),
        );
        // TODO (plus tard) : ref.invalidate(cartProvider);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ajouter au panier')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton(color: Colors.black), backgroundColor: Colors.white, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: DishAvatar(name: dish.name, size: 140)),
          const SizedBox(height: 12),
          Text(dish.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (dish.isVegan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6F3), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Vegan', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              const Spacer(),
              Text('${dish.price.toStringAsFixed(2)} €',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),

          const SizedBox(height: 10),
          avail.when(
            data: (ok) {
              final c = ok ? kPrimaryGreenDark : Colors.red.shade600;
              final t = ok ? 'Disponible aujourd’hui (à ${_hmNow()})' : 'Rupture aujourd’hui';
              return Row(
                children: [
                  Icon(Icons.circle, size: 10, color: c),
                  const SizedBox(width: 6),
                  Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
                ],
              );
            },
            loading: () => const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, _) => Text('Dispo inconnue: $e', style: const TextStyle(color: Colors.red)),
          ),

          const SizedBox(height: 16),
          if (dish.description.isNotEmpty) ...[
            const Text('Détails', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(dish.description),
            const SizedBox(height: 12),
          ],

          const Text('Allergènes', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (dish.allergens.isEmpty)
            Text('Aucun allergène renseigné.', style: TextStyle(color: Colors.grey.shade700))
          else
            Wrap(
              spacing: 6, runSpacing: -6,
              children: dish.allergens.map((a) => AllergenChip(a)).toList(),
            ),
        ],
      ),

      // === BOUTON VERT FIXE EN BAS ===
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: canAdd ? _addToCart : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(canAdd ? 'Ajouter au panier' : 'Indisponible aujourd’hui'),
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryGreenDark,      // ton vert
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
