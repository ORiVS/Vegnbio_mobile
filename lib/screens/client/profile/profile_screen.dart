import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';        // <- authProvider
import '../../../providers/loyalty_provider.dart';     // <- points fidélité
import '../../../widgets/profile/profile_section.dart';
import '../../../widgets/profile/profile_item.dart';
import 'profile_loyalty_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_order_history_screen.dart';
import '../../../models/user.dart';                    // <- VegUser

class ClientProfileScreen extends ConsumerWidget {
  static const route = '/c/profile';
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final loyaltyAsync = ref.watch(loyaltySummaryProvider);
    final VegUser? user = auth.user;

    Widget header;
    if (auth.loading) {
      header = const _ProfileHeader.skeleton();
    } else if (user == null) {
      header = const _ProfileHeader.error();
    } else {
      header = _ProfileHeader(
        name: _displayName(user),
        email: user.email,
        phone: user.profile?.phone,
        pointsChip: loyaltyAsync.maybeWhen(
          data: (sum) => _PointsChip(points: sum.pointsBalance),
          orElse: () => const SizedBox.shrink(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        centerTitle: false,
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).fetchMe();
          ref.invalidate(loyaltySummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 12),
            header,

            // ==== UNE SEULE SECTION ====
            ProfileSection(
              title: 'Mon espace',
              children: [
                ProfileItem(
                  icon: Icons.person,
                  title: 'Informations personnelles',
                  subtitle: user?.role, // CLIENT / FOURNISSEUR / RESTAURATEUR / ADMIN
                  onTap: () => Navigator.pushNamed(context, ProfileEditScreen.route),
                ),
                const Divider(height: 0),

                ProfileItem(
                  icon: Icons.loyalty,
                  title: 'Programme de fidélité',
                  subtitle: 'Consulter mes points, transactions',
                  onTap: () => Navigator.pushNamed(context, ProfileLoyaltyScreen.route),
                ),
                const Divider(height: 0),

                ProfileItem(
                  icon: Icons.receipt_long,
                  title: 'Historique des commandes',
                  onTap: () => Navigator.pushNamed(context, ProfileOrderHistoryScreen.route),
                ),
              ],
            ),
          ],
        ),
      ),

      // ===== BOUTON FIXE EN BAS =====
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  content: const Text('Vous serez redirigé(e) vers l’écran de connexion.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  // TODO: remplace par ta route d’authentification
                  // Navigator.pushNamedAndRemoveUntil(context, AuthScreen.route, (_) => false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Déconnexion effectuée')),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}

class _PointsChip extends StatelessWidget {
  final int points;
  const _PointsChip({required this.points});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$points pts'),
      avatar: const Icon(Icons.star, size: 18),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? phone;
  final Widget? pointsChip;

  const _ProfileHeader({required this.name, required this.email, this.phone, this.pointsChip});

  const _ProfileHeader.skeleton()
      : name = '………',
        email = '………',
        phone = null,
        pointsChip = const SizedBox(
          width: 60,
          height: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.all(Radius.circular(24))),
          ),
        );

  const _ProfileHeader.error()
      : name = 'Non connecté',
        email = '—',
        phone = null,
        pointsChip = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 32, child: Text(initial, style: const TextStyle(fontSize: 24))),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                runSpacing: 4,
                children: [
                  Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(email, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                  if (phone != null && phone!.isNotEmpty) Text(phone!, style: theme.textTheme.bodyMedium),
                  if (pointsChip != null) Padding(padding: const EdgeInsets.only(top: 6), child: pointsChip),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, ProfileLoyaltyScreen.route),
              icon: const Icon(Icons.loyalty),
              label: const Text('Fidélité'),
            ),
          ],
        ),
      ),
    );
  }
}

String _displayName(VegUser u) {
  final fn = (u.firstName).trim();
  final ln = (u.lastName).trim();
  final full = '$fn $ln'.trim();
  return full.isEmpty ? u.email : full;
}
