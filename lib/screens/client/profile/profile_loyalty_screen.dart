import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/loyalty_provider.dart';

class ProfileLoyaltyScreen extends ConsumerWidget {
  static const route = '/c/profile/loyalty';

  const ProfileLoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(loyaltySummaryProvider);
    final txAsync = ref.watch(loyaltyTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Programme de fidélité')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(loyaltySummaryProvider);
          ref.invalidate(loyaltyTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 12),
            summaryAsync.when(
              data: (s) => _LoyaltyHeader(
                points: s.pointsBalance,
                earn: s.earnRatePerEuro,
                redeem: s.redeemRateEuroPerPoint,
                onJoin: null, // si tu veux forcer un bouton "Rejoindre" visible tout le temps, remplace null
              ),
              loading: () => const _LoyaltyHeader.loading(),
              error: (_, __) => _LoyaltyHeader.error(onJoin: () async {
                await ref.read(joinLoyaltyProvider.future);
                ref.invalidate(loyaltySummaryProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adhésion effectuée')));
                }
              }),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Historique des points', style: Theme.of(context).textTheme.titleMedium),
            ),
            txAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Aucune transaction pour le moment.')),
                  );
                }
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: list
                        .map((t) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: t.kind == 'EARN' ? Colors.green.shade50 : Colors.red.shade50,
                        child: Icon(
                          t.kind == 'EARN' ? Icons.trending_up : (t.kind == 'SPEND' ? Icons.trending_down : Icons.sync_alt),
                          color: t.kind == 'EARN' ? Colors.green : (t.kind == 'SPEND' ? Colors.red : Colors.blueGrey),
                        ),
                      ),
                      title: Text('${t.points > 0 ? '+' : ''}${t.points} pts • ${t.kind}'),
                      subtitle: Text(t.reason.isEmpty ? '—' : t.reason),
                      trailing: Text('${t.createdAt.day.toString().padLeft(2, '0')}/${t.createdAt.month.toString().padLeft(2, '0')}/${t.createdAt.year}'),
                    ))
                        .toList(),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Impossible de charger l’historique.'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        ref.invalidate(loyaltyTransactionsProvider);
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoyaltyHeader extends StatelessWidget {
  final int points;
  final String earn;
  final String redeem;
  final VoidCallback? onJoin;

  const _LoyaltyHeader({required this.points, required this.earn, required this.redeem, this.onJoin});
  const _LoyaltyHeader.loading()
      : points = 0,
        earn = '…',
        redeem = '…',
        onJoin = null;
  const _LoyaltyHeader.error({this.onJoin})
      : points = 0,
        earn = '—',
        redeem = '—';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mes avantages', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatTile(label: 'Points', value: '$points'),
              _StatTile(label: 'Gain', value: '$earn pt/€'),
              _StatTile(label: 'Conversion', value: '€/${redeem}pt'.replaceAll('0.', '0.')),
            ],
          ),
          const SizedBox(height: 12),
          if (onJoin != null)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onJoin,
                icon: const Icon(Icons.card_membership),
                label: const Text('Rejoindre le programme'),
              ),
            ),
        ]),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
