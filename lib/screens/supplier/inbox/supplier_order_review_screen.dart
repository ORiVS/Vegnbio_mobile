import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/supplier_orders_provider.dart';
import '../../../providers/supplier_offers_provider.dart';
import '../../../models/supplier_order.dart';
import '../../../services/orders_archive.dart';
import '../../../core/api_service.dart';
import '../../../core/api_paths.dart';

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
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is SupplierOrder) {
      order = args;
    } else {
      // fallback très simple si mauvaise navigation
      Navigator.of(context).pop();
      return;
    }

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

    // On garde une map { itemId: "val" } pour que le provider la transforme
    final Map<int, String> payload = {};
    for (final it in order.items) {
      final raw = _controllers[it.id]!.text.trim();
      // cap local sur "≤ demandé" (le back vérifiera aussi le stock)
      final req = double.tryParse(it.qtyRequested.replaceAll(',', '.')) ?? 0;
      final val = double.tryParse(raw.replaceAll(',', '.'));
      if (val == null || val < 0) {
        _toast('Quantité invalide pour "${it.productName}"');
        return;
      }
      final capped = val > req ? req : val;
      payload[it.id] = capped.toString();
    }

    final ok = await reviewer.submit(order.id, payload);
    if (!mounted) return;

    if (ok) {
      final res = await ApiService.instance.dio.get(ApiPaths.purchasingOrderDetail(order.id));
      await OrdersArchive.instance.upsert(Map<String, dynamic>.from(res.data as Map));

      _toast('Validation envoyée');
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
            // cap local direct (0..req) ; le cap stock sera contrôlé serveur
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
