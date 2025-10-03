// lib/screens/supplier/reviews/supplier_reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/supplier_offers_provider.dart';
import '../../../providers/supplier_reviews_provider.dart';
import '../../../models/supplier_offer.dart';
import '../../../models/offer_review.dart';
import '../../../models/offer_comment.dart';
import 'supplier_review_detail_screen.dart';

class SupplierReviewsScreen extends ConsumerStatefulWidget {
  const SupplierReviewsScreen({super.key});

  @override
  ConsumerState<SupplierReviewsScreen> createState() => _SupplierReviewsScreenState();
}

class _SupplierReviewsScreenState extends ConsumerState<SupplierReviewsScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedOfferId;
  int? _ratingFilter; // 1..5
  late final TabController _tab;
  String _scope = 'MES'; // MES | TOUTES

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final meId = auth.user?.pk;

    final offersAsync = ref.watch(supplierOffersProvider(const SupplierOfferFilters()));

    return offersAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 36),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(supplierOffersProvider(const SupplierOfferFilters())),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (allOffers) {
        // 1) Mes offres vs Toutes
        List<SupplierOffer> scoped;
        if (_scope == 'MES' && meId != null) {
          scoped = allOffers.where((o) => o.supplierId == meId).toList();
        } else {
          scoped = allOffers;
        }

        // 2) Construire les items du sélecteur
        final offerItems = scoped
            .map((o) => DropdownMenuItem<int>(
          value: o.id,
          child: Text('${o.productName}  (#${o.id})'),
        ))
            .toList();

        // 3) Choisir une offre par défaut
        if (_selectedOfferId == null && scoped.isNotEmpty) {
          _selectedOfferId = scoped.first.id;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Avis & Commentaires'),
            bottom: TabBar(
              controller: _tab,
              tabs: const [Tab(text: 'Avis'), Tab(text: 'Commentaires')],
            ),
            actions: [
              // Affichage Mes/Toutes
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _scope,
                  items: const [
                    DropdownMenuItem(value: 'MES', child: Text('Mes offres')),
                    DropdownMenuItem(value: 'TOUTES', child: Text('Toutes')),
                  ],
                  onChanged: (v) => setState(() {
                    _scope = v ?? 'MES';
                    // Recalcul de l'offre sélectionnée si la liste change
                    _selectedOfferId = null;
                  }),
                ),
              ),
              if (_tab.index == 0)
                PopupMenuButton<int?>(
                  onSelected: (v) => setState(() => _ratingFilter = v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: null, child: Text('Toutes notes')),
                    PopupMenuItem(value: 5, child: Text('5★')),
                    PopupMenuItem(value: 4, child: Text('4★')),
                    PopupMenuItem(value: 3, child: Text('3★')),
                    PopupMenuItem(value: 2, child: Text('2★')),
                    PopupMenuItem(value: 1, child: Text('1★')),
                  ],
                  icon: const Icon(Icons.filter_alt),
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedOfferId,
                        items: offerItems,
                        onChanged: (v) => setState(() => _selectedOfferId = v),
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner une offre',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: (_selectedOfferId == null)
                    ? const Center(child: Text('Aucune offre. Changez le filtre “Affichage” ou créez-en une.'))
                    : TabBarView(
                  controller: _tab,
                  children: [
                    _ReviewsTab(offerId: _selectedOfferId!, ratingFilter: _ratingFilter),
                    _CommentsTab(offerId: _selectedOfferId!, myUserId: meId ?? 0),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  final int offerId;
  final int? ratingFilter;
  const _ReviewsTab({required this.offerId, required this.ratingFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ReviewFilters(offerId: offerId, rating: ratingFilter);
    final async = ref.watch(supplierReviewsProvider(filters));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(supplierReviewsProvider(filters)),
      ),
      data: (list) {
        if (list.isEmpty) return const Center(child: Text('Aucun avis pour cette offre.'));
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(supplierReviewsProvider(filters)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ReviewCard(r: list[i]),
          ),
        );
      },
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

class _CommentsTab extends ConsumerStatefulWidget {
  final int offerId;
  final int myUserId;
  const _CommentsTab({required this.offerId, required this.myUserId});

  @override
  ConsumerState<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends ConsumerState<_CommentsTab> {
  final _composer = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(offerCommentsProvider(widget.offerId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _composer,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Écrire un commentaire…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _posting
                  ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              )
                  : IconButton.filled(
                onPressed: _sendComment,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: commentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(offerCommentsProvider(widget.offerId)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Center(child: Text('Aucun commentaire pour cette offre.'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(offerCommentsProvider(widget.offerId)),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _CommentTile(
                    c: list[i],
                    myUserId: widget.myUserId,
                    onChanged: () => ref.invalidate(offerCommentsProvider(widget.offerId)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _sendComment() async {
    final txt = _composer.text.trim();
    if (txt.isEmpty) return;
    setState(() => _posting = true);
    final ok = await ref.read(offerCommentEditorProvider.notifier).create(
      offerId: widget.offerId,
      content: txt,
      isPublic: true,
    );
    if (!mounted) return;
    setState(() => _posting = false);
    if (ok) {
      _composer.clear();
      ref.invalidate(offerCommentsProvider(widget.offerId));
    } else {
      final state = ref.read(offerCommentEditorProvider);
      String msg = 'Envoi impossible';
      if (state is AsyncError) {
        msg = friendlyError(state.error ?? msg);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _CommentTile extends ConsumerWidget {
  final OfferComment c;
  final int myUserId;
  final VoidCallback onChanged;
  const _CommentTile({required this.c, required this.myUserId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = c.authorId == myUserId;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(c.content),
        subtitle: Text('${_d(c.createdAt)}${c.isEdited ? " • (modifié)" : ""}'),
        trailing: canEdit
            ? PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'edit':
                await _edit(context, ref);
                break;
              case 'delete':
                await _delete(context, ref);
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Éditer')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        )
            : null,
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: c.content);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le commentaire'),
        content: TextField(
          controller: ctrl,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok == true) {
      final done = await ref.read(offerCommentEditorProvider.notifier).update(
        offerId: c.offerId,
        commentId: c.id,
        content: ctrl.text.trim(),
      );
      if (!context.mounted) return;
      if (done) {
        onChanged();
      } else {
        final state = ref.read(offerCommentEditorProvider);
        String msg = 'Échec de la mise à jour';
        if (state is AsyncError) {
          msg = friendlyError(state.error ?? msg);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      final done = await ref.read(offerCommentEditorProvider.notifier).delete(
        offerId: c.offerId,
        commentId: c.id,
      );
      if (!context.mounted) return;
      if (done) {
        onChanged();
      } else {
        final state = ref.read(offerCommentEditorProvider);
        String msg = 'Suppression impossible';
        if (state is AsyncError) {
          msg = friendlyError(state.error ?? msg);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
