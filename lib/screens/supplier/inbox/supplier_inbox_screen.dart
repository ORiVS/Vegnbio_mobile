import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/supplier_orders_provider.dart';
import '../../../models/supplier_order.dart';
import 'supplier_order_detail_screen.dart';

class SupplierInboxScreen extends ConsumerStatefulWidget {
  static const route = '/supplier/inbox';
  const SupplierInboxScreen({super.key});

  @override
  ConsumerState<SupplierInboxScreen> createState() => _SupplierInboxScreenState();
}

class _SupplierInboxScreenState extends ConsumerState<SupplierInboxScreen> {
  String? _statusFilter; // null = tous, sinon PENDING_SUPPLIER/...

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(supplierInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boîte de réception'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _statusFilter = v == 'ALL' ? null : v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ALL',                   child: Text('Tous')),
              PopupMenuItem(value: 'PENDING_SUPPLIER',      child: Text('En attente')),
              PopupMenuItem(value: 'CONFIRMED',             child: Text('Confirmées')),
              PopupMenuItem(value: 'PARTIALLY_CONFIRMED',   child: Text('Partielles')),
              PopupMenuItem(value: 'REJECTED',              child: Text('Rejetées')),
              PopupMenuItem(value: 'CANCELLED',             child: Text('Annulées')),
            ],
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (list) {
          final filtered = _statusFilter == null
              ? list
              : list.where((o) => o.status == _statusFilter).toList();

          if (filtered.isEmpty) {
            return const _EmptyInbox();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(supplierInboxProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _OrderTile(o: filtered[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final SupplierOrder o;
  const _OrderTile({required this.o});

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(o.status);
    final subtitle = '${o.items.length} article(s) • ${_d(o.createdAt)}';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text('Commande #${o.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: badge,
        onTap: () => Navigator.pushNamed(
          context,
          SupplierOrderDetailScreen.route,
          arguments: o.id,
        ),
      ),
    );
  }

  Widget _statusBadge(String s) {
    final label = statusLabel(s);
    Color bg;
    switch (s) {
      case 'PENDING_SUPPLIER':    bg = Colors.orange.shade100; break;
      case 'CONFIRMED':           bg = Colors.green.shade100; break;
      case 'PARTIALLY_CONFIRMED': bg = Colors.blue.shade100; break;
      case 'REJECTED':            bg = Colors.red.shade100; break;
      case 'CANCELLED':           bg = Colors.grey.shade300; break;
      default:                    bg = Colors.grey.shade200;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Aucune commande reçue pour le moment.'),
      ),
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
