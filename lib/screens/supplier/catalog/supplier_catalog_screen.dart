import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/supplier_offers_provider.dart';
import '../../../models/supplier_offer.dart';
import '../../../theme/app_colors.dart';
import 'supplier_offer_detail_screen.dart';
import 'supplier_offer_form_screen.dart';

class SupplierCatalogScreen extends ConsumerStatefulWidget {
  const SupplierCatalogScreen({super.key});

  @override
  ConsumerState<SupplierCatalogScreen> createState() => _SupplierCatalogScreenState();
}

class _SupplierCatalogScreenState extends ConsumerState<SupplierCatalogScreen> {
  final _search = TextEditingController();
  String? _status; // DRAFT/PUBLISHED/UNLISTED/FLAGGED
  String? _sort;   // price|-price

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = SupplierOfferFilters(q: _search.text.trim().isEmpty ? null : _search.text.trim(), status: _status, sort: _sort);
    final async = ref.watch(supplierOffersProvider(filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon catalogue'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _status = v == 'ALL' ? null : v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ALL',      child: Text('Tous les statuts')),
              PopupMenuItem(value: 'DRAFT',    child: Text('Brouillon')),
              PopupMenuItem(value: 'PUBLISHED',child: Text('Publié')),
              PopupMenuItem(value: 'UNLISTED', child: Text('Retiré')),
              PopupMenuItem(value: 'FLAGGED',  child: Text('Signalé')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sort = v == 'NONE' ? null : v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'NONE',   child: Text('Tri par défaut')),
              PopupMenuItem(value: 'price',  child: Text('Prix ↑')),
              PopupMenuItem(value: '-price', child: Text('Prix ↓')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher une offre…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF7F7F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              data: (list) {
                if (list.isEmpty) {
                  return _EmptyState(onCreate: () {
                    Navigator.pushNamed(context, SupplierOfferFormScreen.route);
                  });
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(supplierOffersProvider(filters)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemBuilder: (_, i) => _OfferCard(o: list[i]),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: list.length,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-offer',
        onPressed: () => Navigator.pushNamed(context, SupplierOfferFormScreen.route),
        backgroundColor: kPrimaryGreenDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle offre'),
      ),
    );
  }
}

class _OfferCard extends ConsumerWidget {
  final SupplierOffer o;
  const _OfferCard({required this.o});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = _fmtMoney(o.price);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(o.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$price / ${o.unit} • ${_statusLabel(o.status)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            final editor = ref.read(supplierOfferEditorProvider.notifier);
            switch (v) {
              case 'detail':
                Navigator.pushNamed(context, SupplierOfferDetailScreen.route, arguments: o.id);
                break;
              case 'edit':
                Navigator.pushNamed(context, SupplierOfferFormScreen.route, arguments: {'id': o.id});
                break;
              case 'publish':
                final ok = await editor.publish(o.id);
                _toast(context, ok ? 'Offre publiée' : 'Échec publication');
                break;
              case 'unlist':
                final ok = await editor.unlist(o.id);
                _toast(context, ok ? 'Offre retirée' : 'Échec retrait');
                break;
              case 'draft':
                final ok = await editor.draft(o.id);
                _toast(context, ok ? 'Passée en brouillon' : 'Échec');
                break;
              case 'delete':
                final ok = await editor.delete(o.id);
                _toast(context, ok ? 'Offre supprimée' : 'Suppression impossible');
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'detail', child: Text('Aperçu')),
            const PopupMenuItem(value: 'edit',   child: Text('Éditer')),
            if (o.status != 'PUBLISHED') const PopupMenuItem(value: 'publish', child: Text('Publier')),
            if (o.status == 'PUBLISHED') const PopupMenuItem(value: 'unlist',  child: Text('Dépublier')),
            const PopupMenuItem(value: 'draft',  child: Text('Brouillon')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, SupplierOfferDetailScreen.route, arguments: o.id),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56),
            const SizedBox(height: 12),
            const Text('Aucune offre. Créez la première !'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onCreate, child: const Text('Créer ma première offre')),
          ],
        ),
      ),
    );
  }
}

void _toast(BuildContext ctx, String m) => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(m)));
String _fmtMoney(String s) { final v = double.tryParse(s.replaceAll(',', '.')) ?? 0; return '${v.toStringAsFixed(2)}€'; }
String _statusLabel(String s) {
  switch (s) { case 'DRAFT': return 'Brouillon'; case 'PUBLISHED': return 'Publié'; case 'UNLISTED': return 'Retiré'; case 'FLAGGED': return 'Signalé'; default: return s; }
}
