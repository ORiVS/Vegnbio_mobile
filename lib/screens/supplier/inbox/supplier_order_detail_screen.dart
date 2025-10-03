import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/supplier_orders_provider.dart';
import '../../../models/supplier_order.dart';
import 'supplier_order_review_screen.dart';

class SupplierOrderDetailScreen extends ConsumerWidget {
  static const route = '/supplier/inbox/order/detail';
  const SupplierOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final async = ref.watch(supplierOrderDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text('Commande #$id')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (o) => _Body(o: o),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (o) => o.status == 'PENDING_SUPPLIER'
            ? SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              SupplierOrderReviewScreen.route,
              arguments: o,
            ),
            icon: const Icon(Icons.rule),
            label: const Text('Valider la commande'),
          ),
        )
            : null,
        orElse: () => null,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final SupplierOrder o;
  const _Body({required this.o});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(
              'Statut: ${statusLabel(o.status)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Créée le ${_d(o.createdAt)}'
                  '${o.confirmedAt != null ? ' • Confirmée le ${_d(o.confirmedAt!)}' : ''}',
            ),
          ),
        ),
        const SizedBox(height: 12),
        if ((o.note ?? '').trim().isNotEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Note: ${o.note!.trim()}'),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              const ListTile(
                title: Text('Articles', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const Divider(height: 1),
              for (final it in o.items) _ItemRow(it: it),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final SupplierOrderItem it;
  const _ItemRow({required this.it});

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(it.unitPrice.replaceAll(',', '.')) ?? 0;
    final confirmed = it.qtyConfirmed == null ? '—' : it.qtyConfirmed!;
    return ListTile(
      title: Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Demandé: ${it.qtyRequested} ${it.unit} • Confirmé: $confirmed'),
      trailing: Text('${price.toStringAsFixed(2)}€', style: const TextStyle(fontWeight: FontWeight.w600)),
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

String _d(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
