// lib/screens/cart/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../providers/slots_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_service.dart';
import '../../core/api_paths.dart';
import '../../theme/app_colors.dart';
import '../../models/order.dart';
import '../../utils/cart_link_store.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  static const route = '/c/checkout';
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _address1;
  late final TextEditingController _address2;
  final _city = TextEditingController();
  final _postal = TextEditingController();
  late final TextEditingController _phone;

  int? _selectedSlotId;
  int _pointsToUse = 0;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _address1 = TextEditingController(text: user?.profile?.address ?? '');
    _address2 = TextEditingController(text: '');
    _phone    = TextEditingController(text: user?.profile?.phone ?? '');
  }

  @override
  void dispose() {
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    _postal.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final slotsAsync = ref.watch(slotsProvider);
    final loyaltyAsync = ref.watch(loyaltySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Validation de commande')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cartProvider);
          ref.invalidate(slotsProvider);
          ref.invalidate(loyaltySummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Récap panier
            cartAsync.when(
              data: (cart) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: const Text('Sous-total'),
                  subtitle: Text('${cart.items.length} article(s)'),
                  trailing: Text(_fmtMoney(cart.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),

            // Adresse
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Adresse de livraison', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address1,
                      decoration: const InputDecoration(labelText: 'Adresse (ligne 1)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _address2,
                      decoration: const InputDecoration(labelText: 'Adresse (ligne 2)'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _city,
                      decoration: const InputDecoration(labelText: 'Ville'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _postal,
                      decoration: const InputDecoration(labelText: 'Code postal'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
                      keyboardType: TextInputType.phone,
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Créneaux
            slotsAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const ListTile(
                      leading: Icon(Icons.event_busy),
                      title: Text('Aucun créneau disponible'),
                      subtitle: Text('Réessayez plus tard'),
                    ),
                  );
                }
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text('Créneau de livraison', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        ...slots.map((s) {
                          final selected = _selectedSlotId == s.id;
                          final label = '${_fmtDateTime(s.start)} → ${_fmtTime(s.end)}';
                          return ListTile(
                            leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: selected ? kPrimaryGreenDark : null),
                            title: Text(label),
                            onTap: () => setState(() => _selectedSlotId = s.id),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: const Text('Créneaux indisponibles'),
                  subtitle: Text('$e'),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Points fidélité (back already supports)
            _PointsBlock(
              loyaltyAsync: loyaltyAsync,
              cartAsync: cartAsync,
              onChanged: (v) => setState(() => _pointsToUse = v),
              currentValue: _pointsToUse,
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _placing ? null : () => _placeOrder(context),
            icon: _placing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle),
            label: Text(_placing ? 'Validation...' : 'Confirmer la commande'),
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryGreenDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisissez un créneau')));
      return;
    }

    setState(() => _placing = true);
    try {
      final payload = {
        'address_line1': _address1.text.trim(),
        'address_line2': _address2.text.trim(),
        'city': _city.text.trim(),
        'postal_code': _postal.text.trim(),
        'phone': _phone.text.trim(),
        'slot_id': _selectedSlotId,
        'points_to_use': _pointsToUse,
      };

      final res = await ApiService.instance.dio.post(ApiPaths.checkout, data: payload);
      final orderJson = (res.data as Map<String, dynamic>)['order'] as Map<String, dynamic>;
      final order = OrderModel.fromJson(orderJson);

      // Invalidate états globaux
      ref.invalidate(cartProvider);
      ref.invalidate(loyaltySummaryProvider);
      ref.invalidate(loyaltyTransactionsProvider);

      // 🧹 Purge des mappings (les items ont été consommés)
      final user = ref.read(authProvider).user;
      final userId = (user?.pk ?? 0).toString();
      await CartRestaurantLink.clearAllForUser(userId);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        OrderConfirmationScreen.route,
        arguments: {'order': order},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec de la commande")));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}

class _PointsBlock extends StatelessWidget {
  final AsyncValue loyaltyAsync;
  final AsyncValue cartAsync;
  final ValueChanged<int> onChanged;
  final int currentValue;

  const _PointsBlock({
    required this.loyaltyAsync,
    required this.cartAsync,
    required this.onChanged,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Utiliser mes points', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          loyaltyAsync.when(
            data: (sum) {
              final balance = (sum.pointsBalance as int?) ?? 0;
              return cartAsync.when(
                data: (cart) {
                  final subtotal = double.tryParse(cart.total.replaceAll(',', '.')) ?? 0.0;
                  final redeemRate = double.tryParse(sum.redeemRateEuroPerPoint.toString()) ?? 0.0;

                  final maxByBalance = balance;
                  final maxBySubtotal = redeemRate > 0 ? (subtotal / redeemRate).floor() : 0;
                  final maxUsable = [maxByBalance, maxBySubtotal, 0].reduce((a, b) => a < b ? a : b).clamp(0, 1000000);

                  final discount = currentValue * redeemRate;
                  final estimate = (subtotal - discount).clamp(0, double.infinity);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Solde: $balance pts • 1 pt = ${redeemRate.toStringAsFixed(2)}€'),
                      const SizedBox(height: 8),
                      Slider(
                        value: (currentValue).toDouble().clamp(0, maxUsable.toDouble()),
                        min: 0,
                        max: maxUsable.toDouble(),
                        divisions: maxUsable > 0 ? maxUsable : 1,
                        label: '$currentValue pts',
                        onChanged: maxUsable == 0 ? null : (v) => onChanged(v.round()),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Remise: -${discount.toStringAsFixed(2)}€'),
                          Text('Total estimé: ${estimate.toStringAsFixed(2)}€', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      if (maxUsable == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Aucun point utilisable sur ce panier.', style: TextStyle(color: Colors.grey)),
                        ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Panier indisponible'),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Fidélité indisponible'),
          ),
        ]),
      ),
    );
  }
}

// Helpers
String _fmtMoney(String s) {
  final v = double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  return '${v.toStringAsFixed(2)}€';
}
String _two(int x) => x.toString().padLeft(2, '0');
String _fmtDateTime(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';
String _fmtTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
