import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/orders_provider.dart';
import '../../../models/order.dart';

class ProfileOrderHistoryScreen extends ConsumerWidget {
  static const route = '/c/profile/orders';
  const ProfileOrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersProvider),
        child: ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 48),
                  Center(child: Text("Aucune commande pour l’instant.")),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (_, i) => _OrderCard(order: orders[i]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 24),
              const Center(child: Text('Impossible de charger vos commandes.')),
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(ordersProvider),
                  child: const Text('Réessayer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = _fmtDate(order.createdAt);
    final total = _fmtMoney(order.totalPaid);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _OrderDetailsScreen(order: order)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text('Commande #${order.id} • ${_statusLabel(order.status)}'),
            subtitle: Text('Total: $total • $date'),
            trailing: _StatusChip(status: order.status),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color _bg(BuildContext c) {
    switch (status) {
      case 'DELIVERED': return Colors.green.withOpacity(.12);
      case 'OUT_FOR_DELIVERY': return Colors.blue.withOpacity(.12);
      case 'PREPARING': return Colors.orange.withOpacity(.12);
      case 'CANCELLED': return Colors.red.withOpacity(.12);
      default: return Theme.of(c).dividerColor.withOpacity(.25);
    }
  }

  Color _fg(BuildContext c) {
    switch (status) {
      case 'DELIVERED': return Colors.green.shade700;
      case 'OUT_FOR_DELIVERY': return Colors.blue.shade700;
      case 'PREPARING': return Colors.orange.shade800;
      case 'CANCELLED': return Colors.red.shade700;
      default: return Theme.of(c).hintColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _bg(context), borderRadius: BorderRadius.circular(24)),
      child: Text(label, style: TextStyle(color: _fg(context), fontWeight: FontWeight.w600)),
    );
  }
}

class _OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;
  const _OrderDetailsScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    final total = _fmtMoney(order.totalPaid);
    final subtotal = _fmtMoney(order.subtotal);
    final discount = _fmtMoney(order.discountEuros);

    return Scaffold(
      appBar: AppBar(title: Text('Commande #${order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(_statusLabel(order.status)),
              subtitle: Text(_fmtDate(order.createdAt)),
              trailing: _StatusChip(status: order.status),
            ),
          ),
          const SizedBox(height: 12),

          // Adresse & créneau
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Livraison', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(order.addressLine1),
                if ((order.addressLine2 ?? '').isNotEmpty) Text(order.addressLine2!),
                Text('${order.postalCode} ${order.city}'),
                if ((order.phone ?? '').isNotEmpty) Text('Tél: ${order.phone}'),
                const SizedBox(height: 6),
                Text('Créneau #${order.slot}', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Lignes
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: order.items.map((it) {
                final price = _fmtMoney(it.unitPrice);
                final lt = _fmtMoney(it.lineTotal);
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.flatware),
                      title: Text(it.name),
                      subtitle: Text('$price • x${it.quantity}'),
                      trailing: Text(lt, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    if (it != order.items.last) const Divider(height: 0),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Totaux
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _kv('Sous-total', subtotal),
                _kv('Remise points (${order.discountPointsUsed} pts)', '- $discount'),
                const Divider(),
                _kv('Total payé', total, bold: true),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

// ====== helpers ======
String _statusLabel(String s) {
  switch (s) {
    case 'PENDING': return 'En attente';
    case 'PREPARING': return 'En préparation';
    case 'OUT_FOR_DELIVERY': return 'En livraison';
    case 'DELIVERED': return 'Livrée';
    case 'CANCELLED': return 'Annulée';
    default: return s;
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _fmtMoney(String s) {
  final v = double.tryParse(s) ?? 0.0;
  return '${v.toStringAsFixed(2)}€';
}
