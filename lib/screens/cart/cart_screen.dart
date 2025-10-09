// lib/screens/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../models/cart.dart';
import '../../theme/app_colors.dart';
import '../../utils/cart_link_store.dart';
import '../../providers/auth_provider.dart';
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
            return _EmptyCart(onBrowse: () => Navigator.pop(context));
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
                      const Expanded(
                        child: Text('Sous-total', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
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
        data: (cart) => cart.items.isEmpty
            ? null
            : SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushNamed(context, CheckoutScreen.route),
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

class _CartItemTile extends ConsumerStatefulWidget {
  final CartItemModel item;
  final WidgetRef ref;
  const _CartItemTile({required this.item, required this.ref});

  @override
  ConsumerState<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<_CartItemTile> {
  int? _restaurantId;
  String? _restaurantName;

  @override
  void initState() {
    super.initState();
    _loadMapping();
  }

  Future<void> _loadMapping() async {
    final user = ref.read(authProvider).user;
    // VegUser utilise "pk" (pas "id")
    final userId = (user?.pk ?? 0).toString();

    final rid = await CartRestaurantLink.getRestaurantId(
      userId: userId,
      externalItemId: widget.item.externalItemId,
    );
    final rname = await CartRestaurantLink.getRestaurantName(
      userId: userId,
      externalItemId: widget.item.externalItemId,
    );

    if (mounted) {
      setState(() {
        _restaurantId = rid;
        _restaurantName = rname;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitPriceStr = _fmtMoney(widget.item.unitPrice);
    final totalStr = _fmtMoney(widget.item.lineTotal);

    // Sous-titre = prix unitaire + nom resto (si connu)
    final subtitleLines = <String>[unitPriceStr];
    if ((_restaurantName ?? '').isNotEmpty) {
      subtitleLines.add(_restaurantName!);
    } else if (_restaurantId != null) {
      subtitleLines.add('Restaurant #$_restaurantId');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListTile(
          leading: const Icon(Icons.flatware),
          title: Text(widget.item.name),
          subtitle: Text(subtitleLines.join(' • ')),
          // === Bloc d’actions et total : anti-overflow ===
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Retirer 1',
                  onPressed: _restaurantId == null
                      ? null
                      : () async {
                    await setQuantity(
                      widget.ref,
                      restaurantId: _restaurantId!,
                      externalItemId: widget.item.externalItemId,
                      name: widget.item.name,
                      unitPrice: double.tryParse(widget.item.unitPrice) ?? 0,
                      targetQty: widget.item.quantity - 1,
                      restaurantNameForUi: _restaurantName,
                    );
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${widget.item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                  tooltip: 'Ajouter 1',
                  onPressed: _restaurantId == null
                      ? null
                      : () async {
                    await addToCart(
                      widget.ref,
                      restaurantId: _restaurantId!,
                      externalItemId: widget.item.externalItemId,
                      name: widget.item.name,
                      unitPrice: double.tryParse(widget.item.unitPrice) ?? 0,
                      quantity: 1,
                      restaurantNameForUi: _restaurantName,
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const SizedBox(width: 6),
                // Le total prend la place restante et se réduit si nécessaire
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      totalStr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          onLongPress: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Supprimer cet article ?'),
                content: Text(widget.item.name),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                ],
              ),
            );
            if (ok == true) {
              await removeFromCart(
                widget.ref,
                externalItemId: widget.item.externalItemId,
                restaurantId: _restaurantId, // précis si connu
              );
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
