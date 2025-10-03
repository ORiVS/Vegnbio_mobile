import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/supplier_orders_provider.dart';
import '../../../providers/supplier_offers_provider.dart'; // pour récupérer (optionnellement) le stock d’une offre
import '../../../models/supplier_order.dart';

class SupplierOrderReviewScreen extends ConsumerStatefulWidget {
  static const route = '/supplier/inbox/order/review';
  const SupplierOrderReviewScreen({super.key});

  @override
  ConsumerState<SupplierOrderReviewScreen> createState() => _SupplierOrderReviewScreenState();
}

class _SupplierOrderReviewScreenState extends ConsumerState<SupplierOrderReviewScreen> {
  late SupplierOrder order;
  final Map<int, TextEditingController> _controllers = {}; // itemId -> controller

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    order = ModalRoute.of(context)!.settings.arguments as SupplierOrder;
    for (final it in order.items) {
      _controllers[it.id] = TextEditingController(
        text: it.qtyConfirmed?.toString() ?? it.qtyRequested, // prérempli avec demandé
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewerState = ref.watch(supplierOrderReviewerProvider);
    final isLoading = reviewerState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text('Valider commande #${order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const ListTile(
                  title: Text(
                    'Saisir les quantités confirmées',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('Règles: ≤ demandé, ≤ stock (si connu), ≥ 0'),
                ),
                const Divider(height: 1),
                for (final it in order.items) _ReviewRow(it: it, controller: _controllers[it.id]!),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _allZero,
                  icon: const Icon(Icons.block),
                  label: const Text('Tout refuser'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _allRequested,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Tout confirmer'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _reset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Réinitialiser'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isLoading ? null : _submit,
            icon: const Icon(Icons.send),
            label: Text(isLoading ? 'Envoi…' : 'Envoyer la validation'),
          ),
          const SizedBox(height: 8),
          // Affichage d’erreur lisible si l’éditeur a renvoyé une erreur (validation côté back)
          reviewerState.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                e.toString(),
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _allZero() {
    for (final c in _controllers.values) c.text = '0';
    setState(() {});
  }

  void _allRequested() {
    for (final it in order.items) {
      _controllers[it.id]!.text = it.qtyRequested;
    }
    setState(() {});
  }

  void _reset() {
    for (final it in order.items) {
      _controllers[it.id]!.text = it.qtyConfirmed ?? it.qtyRequested;
    }
    setState(() {});
  }

  Future<void> _submit() async {
    final reviewer = ref.read(supplierOrderReviewerProvider.notifier);

    // validation locale + cap (≤ demandé) ; cap par stock si connu
    final Map<int, String> payload = {};
    for (final it in order.items) {
      final txt = _controllers[it.id]!.text.trim();
      final val = double.tryParse(txt.replaceAll(',', '.'));
      final req = double.tryParse(it.qtyRequested.replaceAll(',', '.')) ?? 0;

      if (val == null || val < 0) {
        _toast('Quantité invalide pour "${it.productName}"');
        return;
      }

      var confirmed = val > req ? req : val; // cap demandé

      // cap optionnel par stock si dispo
      final offerAsync = ref.read(supplierOfferDetailProvider(it.offerId));
      offerAsync.whenData((offer) {
        final stock = double.tryParse(offer.stockQty.replaceAll(',', '.'));
        if (stock != null && confirmed > stock) {
          confirmed = stock;
        }
      });

      payload[it.id] = confirmed.toString();
    }

    final ok = await reviewer.submit(order.id, payload);
    if (!mounted) return;

    if (ok) {
      _toast('Validation envoyée');
      // refresh inbox + détail si on revient
      ref.invalidate(supplierInboxProvider);
      ref.invalidate(supplierOrderDetailProvider(order.id));
      Navigator.pop(context); // sortir de la review
      Navigator.pop(context); // sortir du détail → retour inbox
    } else {
      final msg = reviewer.lastError ?? 'Erreur lors de la validation';
      _toast(msg);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

class _ReviewRow extends ConsumerWidget {
  final SupplierOrderItem it;
  final TextEditingController controller;
  const _ReviewRow({required this.it, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer (optionnellement) le stock de l’offre pour afficher un cap indicatif
    final offerAsync = ref.watch(supplierOfferDetailProvider(it.offerId));
    final req = double.tryParse(it.qtyRequested.replaceAll(',', '.')) ?? 0;

    return ListTile(
      title: Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: offerAsync.when(
        loading: () => Text('Demandé: ${it.qtyRequested} ${it.unit} • Stock: …'),
        error: (_, __) => Text('Demandé: ${it.qtyRequested} ${it.unit} • Stock: —'),
        data: (offer) {
          final stock = double.tryParse(offer.stockQty.replaceAll(',', '.')) ?? 0;
          final cap = stock < req ? stock : req;
          return Text('Demandé: ${it.qtyRequested} ${it.unit} • Stock: ${offer.stockQty} • Max: $cap');
        },
      ),
      trailing: SizedBox(
        width: 110,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.end,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Confirmé'),
          onChanged: (_) {
            // cap local direct (0..req); le cap stock est appliqué au submit
            final val = double.tryParse(controller.text.replaceAll(',', '.'));
            if (val == null) return;
            final capped = val > req ? req : (val < 0 ? 0 : val);
            if (capped != val) {
              controller.text = capped.toString();
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          },
        ),
      ),
      dense: true,
    );
  }
}

String statusLabel(String s) {
  switch (s) {
    case 'PENDING_SUPPLIER':    return 'En attente';
    case 'CONFIRMED':           return 'Confirmée';
    case 'PARTIALLY_CONFIRMED': return 'Partielle';
    case 'REJECTED':            return 'Rejetée';
    case 'CANCELLED':           return 'Annulée';
    default:                    return s;
  }
}
