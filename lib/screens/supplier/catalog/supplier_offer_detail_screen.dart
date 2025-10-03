import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/supplier_offers_provider.dart';
import '../../../models/supplier_offer.dart';
import '../../../theme/app_colors.dart';
import 'supplier_offer_form_screen.dart';

class SupplierOfferDetailScreen extends ConsumerWidget {
  static const route = '/supplier/offer/detail';
  const SupplierOfferDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = (ModalRoute.of(context)!.settings.arguments as int);
    final async = ref.watch(supplierOfferDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l’offre')),
      body: async.when(
        data: (o) => _Body(o: o),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (o) => SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    SupplierOfferFormScreen.route,
                    arguments: {'id': o.id},
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Éditer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final ed = ref.read(supplierOfferEditorProvider.notifier);
                    final ok = (o.status == 'PUBLISHED')
                        ? await ed.unlist(o.id)
                        : await ed.publish(o.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? (o.status == 'PUBLISHED' ? 'Offre dépubliée' : 'Offre publiée')
                          : 'Action impossible'),
                    ));
                    ref.invalidate(supplierOfferDetailProvider(o.id));
                    ref.invalidate(supplierOffersProvider);
                  },
                  icon: Icon(o.status == 'PUBLISHED' ? Icons.visibility_off : Icons.public),
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimaryGreenDark,
                    foregroundColor: Colors.white,
                  ),
                  label: Text(o.status == 'PUBLISHED' ? 'Dépublier' : 'Publier'),
                ),
              ),
            ],
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final SupplierOffer o;
  const _Body({required this.o});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(o.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${_fmtMoney(o.price)} / ${o.unit} • ${_statusLabel(o.status)}'),
            trailing: o.avgRating == null
                ? const Text('—')
                : Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: Colors.amber),
              Text(o.avgRating!.toStringAsFixed(1)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        if ((o.description ?? '').isNotEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(o.description!),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Disponibilité', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Stock: ${o.stockQty} ${o.unit} • Qté mini: ${o.minOrderQty} ${o.unit}'),
              const SizedBox(height: 4),
              Text('Fenêtre: ${_d(o.availableFrom)} → ${_d(o.availableTo)}'),
              const SizedBox(height: 4),
              Text('Région: ${o.region} • Bio: ${o.isBio ? "Oui" : "Non"}'),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Historique des statuts', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Dernières transitions (placeholder).'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _fmtMoney(String s) {
  final v = double.tryParse(s.replaceAll(',', '.')) ?? 0;
  return '${v.toStringAsFixed(2)}€';
}
String _d(DateTime? d) =>
    d == null ? '—' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
