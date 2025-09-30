import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/offer_review.dart';
import '../../../providers/supplier_offers_provider.dart';

class SupplierReviewDetailScreen extends ConsumerWidget {
  static const route = '/supplier/review/detail';
  const SupplierReviewDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ModalRoute.of(context)!.settings.arguments as OfferReview;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l’avis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, color: Colors.amber),
                Text(review.rating.toString()),
              ]),
              title: Text(review.comment?.isNotEmpty == true ? review.comment! : '(Sans commentaire)'),
              subtitle: Text('$_d(review.createdAt)'),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Modération', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              final reasonCtrl = TextEditingController(text: 'Abus sur avis ');
              final detailsCtrl = TextEditingController();
              final ok = await showDialog<bool>(context: context, builder: (_) {
                return AlertDialog(
                  title: const Text('Signaler cette offre (lié à l’avis)'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Raison')),
                    const SizedBox(height: 8),
                    TextField(controller: detailsCtrl, decoration: const InputDecoration(labelText: 'Détails (optionnel)')),
                  ]),
                  actions: [
                    TextButton(onPressed: ()=>Navigator.pop(context, false), child: const Text('Annuler')),
                    FilledButton(onPressed: ()=>Navigator.pop(context, true), child: const Text('Envoyer')),
                  ],
                );
              });
              if (ok == true) {
                final ed = ref.read(supplierOfferEditorProvider.notifier);
                final done = await ed.flagOffer(review.offerId, reason: reasonCtrl.text.trim(), details: detailsCtrl.text.trim());
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done ? 'Signalement envoyé' : 'Échec du signalement')));
              }
            },
            icon: const Icon(Icons.flag),
            label: const Text('Signaler à la modération'),
          ),
          const SizedBox(height: 12),
          const Text('Les signalements sont traités par la modération.'),
        ],
      ),
    );
  }
}

String _d(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
