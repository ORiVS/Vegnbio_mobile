import 'package:flutter/material.dart';
import '../../models/order.dart';

class OrderConfirmationScreen extends StatelessWidget {
  static const route = '/c/checkout/confirmation';
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final OrderModel order = args['order'] as OrderModel;

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
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text('Commande confirmée • ${_statusLabel(order.status)}'),
              subtitle: Text(_fmtDate(order.createdAt)),
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

          // Items
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

          const SizedBox(height: 16),
          Center(
            child: Text('Un email de confirmation vous a été envoyé (si configuré).',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: 24),
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

// Helpers
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
  final v = double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  return '${v.toStringAsFixed(2)}€';
}
