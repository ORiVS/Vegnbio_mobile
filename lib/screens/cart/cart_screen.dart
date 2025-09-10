import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart.dart';
import '../../theme/app_colors.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  static const route = '/c/cart';
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon panier')),
      body: cartAsync.when(
        data: (cart) {
          if (cart.items.isEmpty) {
            return _EmptyCart(
              onBrowse: () => Navigator.pop(context),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...cart.items.map((it) => _CartItemTile(item: it, ref: ref)).toList(),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Sous-total', style: TextStyle(fontWeight: FontWeight.w600))),
                      Text(_fmtMoney(cart.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Impossible de charger le panier'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.invalidate(cartProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: cartAsync.maybeWhen(
        data: (cart) => cart.items.isEmpty ? null : SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pushNamed(context, CheckoutScreen.route);
              },
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Choisir créneau & valider'),
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItemModel item;
  final WidgetRef ref;
  const _CartItemTile({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    final price = _fmtMoney(item.unitPrice);
    final total = _fmtMoney(item.lineTotal);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListTile(
          leading: const Icon(Icons.flatware),
          title: Text(item.name),
          subtitle: Text('$price'),
          trailing: SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Retirer 1',
                  onPressed: () async {
                    await setQuantity(
                      ref,
                      externalItemId: item.externalItemId,
                      name: item.name,
                      unitPrice: double.tryParse(item.unitPrice) ?? 0,
                      targetQty: item.quantity - 1,
                    );
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                  tooltip: 'Ajouter 1',
                  onPressed: () async {
                    await addToCart(
                      ref,
                      externalItemId: item.externalItemId,
                      name: item.name,
                      unitPrice: double.tryParse(item.unitPrice) ?? 0,
                      quantity: 1,
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const SizedBox(width: 8),
                Text(total, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          onLongPress: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Supprimer cet article ?'),
                content: Text(item.name),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                ],
              ),
            );
            if (ok == true) {
              await removeFromCart(ref, externalItemId: item.externalItemId);
            }
          },
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyCart({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 56),
            const SizedBox(height: 12),
            const Text('Votre panier est vide'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onBrowse, child: const Text('Découvrir les menus')),
          ],
        ),
      ),
    );
  }
}

String _fmtMoney(String s) {
  final v = double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  return '${v.toStringAsFixed(2)}€';
}
