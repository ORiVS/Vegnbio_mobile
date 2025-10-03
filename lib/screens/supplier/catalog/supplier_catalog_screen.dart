// lib/screens/supplier/catalog/supplier_catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/supplier_offers_provider.dart';
import '../../../models/supplier_offer.dart';
import '../../../theme/app_colors.dart';
import 'supplier_offer_detail_screen.dart';
import 'supplier_offer_form_screen.dart';

class SupplierCatalogScreen extends ConsumerStatefulWidget {
  static const route = '/supplier/catalog';
  const SupplierCatalogScreen({super.key});

  @override
  ConsumerState<SupplierCatalogScreen> createState() => _SupplierCatalogScreenState();
}

class _SupplierCatalogScreenState extends ConsumerState<SupplierCatalogScreen> {
  final _search = TextEditingController();
  String? _status; // DRAFT | PUBLISHED | UNLISTED | FLAGGED (filtre local)
  String? _sort;   // "price" | "-price" (tri back)

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final meId = auth.user?.pk;

    final filters = SupplierOfferFilters(
      q: _search.text.trim().isEmpty ? null : _search.text.trim(),
      sort: _sort, // tri géré par le back
    );
    final async = ref.watch(supplierOffersProvider(filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes offres'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _status = (v == 'ALL') ? null : v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ALL',       child: Text('Tous les statuts')),
              PopupMenuItem(value: 'DRAFT',     child: Text('Brouillon')),
              PopupMenuItem(value: 'PUBLISHED', child: Text('Publié')),
              PopupMenuItem(value: 'UNLISTED',  child: Text('Retiré')),
              PopupMenuItem(value: 'FLAGGED',   child: Text('Signalé')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sort = (v == 'NONE') ? null : v),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (listAll) {
                // ✅ Si meId est null (ex: /me pas encore chargé), on n’applique pas le filtre
                final mine = (meId == null)
                    ? listAll
                    : listAll.where((o) => o.supplierId == meId).toList();

                // Filtre local par statut (le back n’a pas de param status)
                final list = (_status == null)
                    ? mine
                    : mine.where((o) => o.status == _status).toList();

                if (list.isEmpty) {
                  return _EmptyState(
                    onCreate: () => Navigator.pushNamed(
                      context,
                      SupplierOfferFormScreen.route,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(supplierOffersProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _OfferCard(o: list[i]),
                  ),
                );
              },
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
                _act(context, await editor.publish(o.id), 'Offre publiée', 'Échec publication');
                break;
              case 'unlist':
                _act(context, await editor.unlist(o.id), 'Offre retirée', 'Échec retrait');
                break;
              case 'draft':
                _act(context, await editor.draft(o.id), 'Passée en brouillon', 'Échec');
                break;
              case 'delete':
                _act(context, await editor.delete(o.id), 'Offre supprimée', 'Suppression impossible');
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'detail', child: Text('Aperçu')),
            const PopupMenuItem(value: 'edit',   child: Text('Éditer')),
            if (o.status != 'PUBLISHED')
              const PopupMenuItem(value: 'publish', child: Text('Publier')),
            if (o.status == 'PUBLISHED')
              const PopupMenuItem(value: 'unlist',  child: Text('Dépublier')),
            const PopupMenuItem(value: 'draft',  child: Text('Brouillon')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, SupplierOfferDetailScreen.route, arguments: o.id),
      ),
    );
  }

  void _act(BuildContext ctx, bool ok, String okMsg, String koMsg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(ok ? okMsg : koMsg)));
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

String _fmtMoney(String s) {
  final v = double.tryParse(s.replaceAll(',', '.')) ?? 0;
  return '${v.toStringAsFixed(2)}€';
}

String _statusLabel(String s) {
  switch (s) {
    case 'DRAFT':
      return 'Brouillon';
    case 'PUBLISHED':
      return 'Publié';
    case 'UNLISTED':
      return 'Retiré';
    case 'FLAGGED':
      return 'Signalé';
    default:
      return s;
  }
}
