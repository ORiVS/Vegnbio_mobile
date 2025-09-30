import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/supplier_reviews_provider.dart';
import '../../../models/offer_review.dart';
import 'supplier_review_detail_screen.dart';

class SupplierReviewsScreen extends ConsumerStatefulWidget {
  const SupplierReviewsScreen({super.key});

  @override
  ConsumerState<SupplierReviewsScreen> createState() => _SupplierReviewsScreenState();
}

class _SupplierReviewsScreenState extends ConsumerState<SupplierReviewsScreen> {
  int? _rating;

  @override
  Widget build(BuildContext context) {
    final filters = ReviewFilters(rating: _rating);
    final async = ref.watch(supplierReviewsProvider(filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avis reçus'),
        actions: [
          PopupMenuButton<int?>(
            onSelected: (v) => setState(()=>_rating = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Toutes notes')),
              PopupMenuItem(value: 5, child: Text('5★')),
              PopupMenuItem(value: 4, child: Text('4★')),
              PopupMenuItem(value: 3, child: Text('3★')),
              PopupMenuItem(value: 2, child: Text('2★')),
              PopupMenuItem(value: 1, child: Text('1★')),
            ],
          )
        ],
      ),
      body: async.when(
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('Aucun avis.'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(supplierReviewsProvider(filters)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i) => _ReviewCard(r: list[i]),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: list.length,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final OfferReview r;
  const _ReviewCard({required this.r});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star, color: Colors.amber),
          Text(r.rating.toString()),
        ]),
        title: Text(r.comment?.isNotEmpty == true ? r.comment! : '(Sans commentaire)'),
        subtitle: Text('${_d(r.createdAt)} • offre #${r.offerId}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, SupplierReviewDetailScreen.route, arguments: r),
      ),
    );
  }
}

String _d(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
