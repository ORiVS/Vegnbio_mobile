import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/reservations_provider.dart';
import '../../core/api_service.dart';
import '../../core/api_paths.dart';
import '../../core/api_error.dart';
import '../../widgets/api_result_dialogs.dart';
import '../../widgets/status_chip.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class ClientReservationsScreen extends ConsumerWidget {
  static const route = '/c/reservations';
  const ClientReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // 🔒 Non connecté → UI explicite (pas d’appel réseau)
    if (!auth.isAuthenticated || auth.user == null) {
      return const _AuthRequiredView(
        title: 'Mes réservations',
        message: 'Vous devez être connecté pour voir vos réservations.',
      );
    }

    final async = ref.watch(myReservationsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes réservations',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kPrimaryGreenDark,
                letterSpacing: .2,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: async.when(
                data: (list) {
                  if (list.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(myReservationsProvider.future),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text('Aucune réservation',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Vos futures réservations confirmées apparaîtront ici.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(myReservationsProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (c, i) {
                        final r = list[i];
                        final isFull = r.fullRestaurant;
                        final title = isFull ? (r.restaurantName ?? 'Restaurant') : (r.roomName ?? 'Salle');
                        final line2 = isFull ? 'Restaurant entier' : (r.restaurantName ?? '—');
                        final dateLine = '${r.date}   ${_hm(r.startTime)} – ${_hm(r.endTime)}';

                        return _ReservationCard(
                          icon: Icons.event_available,
                          title: title,
                          line2: line2,
                          dateLine: dateLine,
                          status: r.status,
                          canCancel: r.status == 'PENDING',
                          onCancel: () => _onCancel(c, ref, r.id),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                // ❌ Auth error → UI explicite (pas le DioException brut)
                error: (e, _) {
                  if (_looksLikeAuthError(e)) {
                    return const _AuthRequiredView(
                      title: 'Mes réservations',
                      message: 'Vous devez être connecté pour voir vos réservations.',
                    );
                  }
                  return Center(child: Text('Erreur : $e'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hm(String s) => s.length >= 5 ? s.substring(0, 5) : s;

  Future<void> _onCancel(BuildContext context, WidgetRef ref, int id) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Annuler la demande ?',
      message: 'Seules les réservations en attente peuvent être annulées.',
      confirmLabel: 'Oui, annuler',
    );
    if (confirm != true) return;

    try {
      await ApiService.instance.dio.post(ApiPaths.reservationCancel(id));
      if (!context.mounted) return;
      await showSuccessDialog(context, title: 'Réservation annulée.');
      ref.invalidate(myReservationsProvider);
    } on DioException catch (e) {
      if (!context.mounted) return;
      if (_looksLikeAuthError(e)) {
        // Remplace l’erreur par l’UI “Se connecter”
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const _AuthRequiredView(
              title: 'Mes réservations',
              message: 'Vous devez être connecté pour voir vos réservations.',
            ),
          ),
        );
        return;
      }
      await showErrorDialog(context, title: 'Annulation impossible.', error: ApiError.fromDio(e));
    } catch (e) {
      if (!context.mounted) return;
      await showErrorDialog(context, title: 'Erreur inattendue.', error: ApiError(messages: [e.toString()]));
    }
  }
}

class _ReservationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String line2;
  final String dateLine;
  final String status;
  final bool canCancel;
  final VoidCallback onCancel;

  const _ReservationCard({
    required this.icon,
    required this.title,
    required this.line2,
    required this.dateLine,
    required this.status,
    required this.canCancel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: .6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: kPrimaryGreenDark),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(line2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Text(dateLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(status),
                if (canCancel) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        side: BorderSide(color: Colors.red.shade200),
                        foregroundColor: Colors.red.shade700,
                      ),
                      child: const Text('Annuler', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// UI dédiée “connexion nécessaire”
class _AuthRequiredView extends StatelessWidget {
  final String title;
  final String message;
  const _AuthRequiredView({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: kPrimaryGreenDark)),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 42, color: kPrimaryGreenDark),
                    const SizedBox(height: 10),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(context, LoginScreen.route),
                      child: const Text('Se connecter'),
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

/// Détecte les erreurs d’auth 401 OU le guard réseau qui annule la requête
bool _looksLikeAuthError(Object e) {
  if (e is DioException) {
    if (e.response?.statusCode == 401) return true;
    if (e.type == DioExceptionType.cancel && (e.error?.toString() == 'auth_required')) return true;
  }
  return false;
}
