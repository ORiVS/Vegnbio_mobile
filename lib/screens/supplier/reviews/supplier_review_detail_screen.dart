// lib/screens/supplier/reviews/supplier_review_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../models/offer_review.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/supplier_offers_provider.dart';
import '../../../providers/supplier_reviews_provider.dart'; // friendlyError pour formater les erreurs

class SupplierReviewDetailScreen extends ConsumerWidget {
  static const route = '/supplier/review/detail';
  const SupplierReviewDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ModalRoute.of(context)!.settings.arguments as OfferReview;

    final meRole = ref.watch(authProvider).user?.role ?? 'CLIENT';
    final canFlag = meRole == 'RESTAURATEUR' || meRole == 'ADMIN';

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
              subtitle: Text(_d(review.createdAt)),
            ),
          ),
          const SizedBox(height: 12),
          if (canFlag) ...[
            const Text('Modération', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final reasonCtrl = TextEditingController(text: 'Abus sur avis');
                final detailsCtrl = TextEditingController();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Signaler l’offre liée'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Raison')),
                      const SizedBox(height: 8),
                      TextField(controller: detailsCtrl, decoration: const InputDecoration(labelText: 'Détails (optionnel)')),
                    ]),
                    actions: [
                      TextButton(onPressed: ()=>Navigator.pop(context, false), child: const Text('Annuler')),
                      FilledButton(onPressed: ()=>Navigator.pop(context, true), child: const Text('Envoyer')),
                    ],
                  ),
                );
                if (ok == true) {
                  String msg;
                  try {
                    final ed = ref.read(supplierOfferEditorProvider.notifier);
                    final done = await ed.flagOffer(
                      review.offerId,
                      reason: reasonCtrl.text.trim(),
                      details: detailsCtrl.text.trim(),
                    );
                    if (!context.mounted) return;
                    if (done) {
                      msg = 'Signalement envoyé';
                    } else {
                      // Essayer de lire l’erreur stockée côté provider si dispo
                      final st = ref.read(supplierOfferEditorProvider);
                      if (st is AsyncError) {
                        msg = friendlyError(st.error ?? 'Échec du signalement');
                      } else {
                        msg = 'Échec du signalement';
                      }
                    }
                  } catch (e) {
                    msg = friendlyError(e);
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                }
              },
              icon: const Icon(Icons.flag),
              label: const Text('Signaler l’offre'),
            ),
            const SizedBox(height: 12),
            const Text('Les signalements sont transmis à la modération.'),
          ],
        ],
      ),
    );
  }
}

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
