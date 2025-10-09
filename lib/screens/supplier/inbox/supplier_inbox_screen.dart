// lib/screens/supplier/inbox/supplier_inbox_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/supplier_orders_provider.dart';
import '../../../models/supplier_order.dart';

import '../../../providers/event_invites_provider.dart';
import '../../../models/event_invite.dart';

import 'supplier_order_detail_screen.dart';

// Archive locale + providers
import '../../../services/orders_archive.dart';
import '../../../providers/orders_archive_provider.dart';

import '../../../core/api_service.dart';
import '../../../core/api_paths.dart';

class SupplierInboxScreen extends ConsumerStatefulWidget {
  static const route = '/supplier/inbox';
  const SupplierInboxScreen({super.key});

  @override
  ConsumerState<SupplierInboxScreen> createState() => _SupplierInboxScreenState();
}

class _SupplierInboxScreenState extends ConsumerState<SupplierInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String? _statusFilter; // null = tous ; sinon PENDING_SUPPLIER/…

  // tri courant (par défaut: date desc)
  ArchiveSort _sort = ArchiveSort.dateDesc;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    // ⚠️ Ne pas modifier un provider dans build()
    // On pousse le tri par défaut APRÈS le premier frame.
    Future.microtask(() {
      final cur = ref.read(archiveFiltersProvider);
      ref.read(archiveFiltersProvider.notifier).state = cur.copyWith(sort: _sort);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(eventInvitesProvider);
    final badge = invitesAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Boîte de réception'),
            const SizedBox(width: 8),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$badge invitations',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Commandes'),
            Tab(text: 'Invitations'),
          ],
        ),
        actions: [
          if (_tab.index == 0) ...[
            // TRI
            PopupMenuButton<ArchiveSort>(
              tooltip: 'Trier',
              icon: const Icon(Icons.sort),
              onSelected: (s) {
                setState(() => _sort = s);
                // ✅ Modif provider depuis un callback UI (pas pendant build)
                final cur = ref.read(archiveFiltersProvider);
                ref.read(archiveFiltersProvider.notifier).state = cur.copyWith(sort: _sort);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: ArchiveSort.dateDesc,            child: Text('Date ↓')),
                PopupMenuItem(value: ArchiveSort.dateAsc,             child: Text('Date ↑')),
                PopupMenuItem(value: ArchiveSort.totalConfirmedDesc,  child: Text('Confirmé ↓')),
                PopupMenuItem(value: ArchiveSort.totalConfirmedAsc,   child: Text('Confirmé ↑')),
              ],
            ),
            // FILTRE statut
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (v) => setState(() => _statusFilter = v == 'ALL' ? null : v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'ALL',                  child: Text('Tous')),
                PopupMenuItem(value: 'PENDING_SUPPLIER',     child: Text('En attente')),
                PopupMenuItem(value: 'CONFIRMED',            child: Text('Confirmées')),
                PopupMenuItem(value: 'PARTIALLY_CONFIRMED',  child: Text('Partielles')),
                PopupMenuItem(value: 'REJECTED',             child: Text('Rejetées')),
                PopupMenuItem(value: 'CANCELLED',            child: Text('Annulées')),
              ],
            ),
          ],
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OrdersTab(statusFilter: _statusFilter),
          const _InvitesTab(),
        ],
      ),
    );
  }
}

/* ============================================================
   Onglet Commandes : combine inbox (API) + historique (local)
   ============================================================ */

class _OrdersTab extends ConsumerWidget {
  final String? statusFilter;
  const _OrdersTab({required this.statusFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync    = ref.watch(supplierInboxProvider);           // API: PENDING_SUPPLIER
    final archiveAsync  = ref.watch(ordersArchiveProvider);           // local: tout
    final filteredArchive = ref.watch(filteredArchiveOrdersProvider); // tri/filtre (tri lu via archiveFiltersProvider)

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(supplierInboxProvider);
        ref.invalidate(ordersArchiveProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // INBOX
          inboxAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Erreur (inbox) : $e', style: const TextStyle(color: Colors.red)),
            ),
            data: (pending) {
              final p = (statusFilter == null)
                  ? pending
                  : pending.where((o) => o.status == statusFilter).toList();

              if (p.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('À traiter'),
                  const SizedBox(height: 8),
                  ...p.map((o) => _OrderTile(o: o)),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

          // HISTORIQUE
          archiveAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Erreur (historique) : $e', style: const TextStyle(color: Colors.red)),
            ),
            data: (_) {
              // enlever doublons avec l’inbox
              final inboxIds = inboxAsync.maybeWhen(
                data: (p) => p.map((o) => o.id).toSet(),
                orElse: () => <int>{},
              );
              final hist = filteredArchive.where((o) => !inboxIds.contains(o.id)).toList();

              final histFiltered = statusFilter == null
                  ? hist
                  : hist.where((o) => o.status == statusFilter).toList();

              if (histFiltered.isEmpty) {
                final hadInbox = inboxAsync.maybeWhen(
                  data: (p) => p.isNotEmpty,
                  orElse: () => false,
                );
                if (!hadInbox) return const _EmptyInbox(text: 'Aucune commande.');
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Historique'),
                  const SizedBox(height: 8),
                  ...histFiltered.map((o) => _OrderTile(o: o)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16));
  }
}

class _OrderTile extends ConsumerWidget {
  final SupplierOrder o;
  const _OrderTile({required this.o});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = _statusBadge(o.status);
    final subtitle = '${o.items.length} article(s) • ${_d(o.createdAt)}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text('Commande #${o.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: badge,
        onTap: () async {
          // Met à jour l’archive avec la version API récente
          try {
            final res = await ApiService.instance.dio.get(ApiPaths.purchasingOrderDetail(o.id));
            final data = Map<String, dynamic>.from(res.data as Map);
            await OrdersArchive.instance.upsert(Map<String, dynamic>.from(res.data as Map));
          } catch (_) {}
          if (!context.mounted) return;

          Navigator.pushNamed(
            context,
            SupplierOrderDetailScreen.route,
            arguments: o.id,
          );
        },
      ),
    );
  }

  Widget _statusBadge(String s) {
    final label = statusLabel(s);
    Color bg;
    switch (s) {
      case 'PENDING_SUPPLIER': bg = Colors.orange.shade100; break;
      case 'CONFIRMED': bg = Colors.green.shade100; break;
      case 'PARTIALLY_CONFIRMED': bg = Colors.blue.shade100; break;
      case 'REJECTED': bg = Colors.red.shade100; break;
      case 'CANCELLED': bg = Colors.grey.shade300; break;
      default: bg = Colors.grey.shade200;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/* ============================================================
   Onglet Invitations (inchangé)
   ============================================================ */

class _InvitesTab extends ConsumerWidget {
  const _InvitesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventInvitesProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (list) {
        if (list.isEmpty) return const _EmptyInbox(text: 'Aucune invitation pour le moment.');
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(eventInvitesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _InviteCard(inv: list[i]),
          ),
        );
      },
    );
  }
}

class _InviteCard extends ConsumerWidget {
  final EventInviteModel inv;
  const _InviteCard({required this.inv});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = _fmtDate(inv.event.date);
    final h = '${_fmtTime(inv.event.startTime)} – ${_fmtTime(inv.event.endTime)}';
    final deadline = inv.supplierDeadlineAt ?? inv.expiresAt;
    final dlStr = deadline == null ? '—' : _d(deadline);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(inv.event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$d • $h\nDate limite: $dlStr'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            final actions = ref.read(eventInviteActionsProvider.notifier);
            bool ok = false;
            if (v == 'accept') ok = await actions.accept(inv.id);
            if (v == 'decline') ok = await actions.decline(inv.id);
            if (!context.mounted) return;
            if (ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(v == 'accept' ? 'Invitation acceptée' : 'Invitation refusée')),
              );
              ref.invalidate(eventInvitesProvider);
            } else {
              final msg = ref.read(eventInviteActionsProvider.notifier).lastError ?? 'Action impossible';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'accept', child: Text('Accepter')),
            PopupMenuItem(value: 'decline', child: Text('Refuser')),
          ],
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  final String text;
  const _EmptyInbox({this.text = '—'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text),
      ),
    );
  }
}

/* ============================================================
   Helpers
   ============================================================ */

String _d(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmtDate(String ymd) {
  if (ymd.length >= 10) return '${ymd.substring(8,10)}/${ymd.substring(5,7)}/${ymd.substring(0,4)}';
  return ymd;
}

String _fmtTime(String hms) {
  if (hms.length >= 5) return hms.substring(0,5);
  return hms;
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
