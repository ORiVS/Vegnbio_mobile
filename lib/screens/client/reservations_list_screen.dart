// lib/screens/client/reservations_list_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/reservations_provider.dart';
import '../../core/api_service.dart';
import '../../core/api_paths.dart';
import '../../core/api_error.dart';
import '../../widgets/api_result_dialogs.dart';
import '../../widgets/status_chip.dart';
import '../../theme/app_colors.dart';

class ClientReservationsScreen extends ConsumerWidget {
  static const route = '/c/reservations';
  const ClientReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myReservationsProvider);

    return SafeArea(
      child: Padding(
        // titre un peu plus bas
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
                          Text('Vos réservations à venir apparaîtront ici.',
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
                        final title = isFull
                            ? (r.restaurantName ?? 'Restaurant')
                            : (r.roomName ?? 'Salle');
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
                error: (e, _) => Center(child: Text('Erreur : $e')),
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
      title: 'Annuler la réservation ?',
      message: 'Cette action est définitive.',
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
      await showErrorDialog(context, title: 'Annulation impossible.', error: ApiError.fromDio(e));
    } catch (e) {
      if (!context.mounted) return;
      await showErrorDialog(context, title: 'Erreur inattendue.', error: ApiError(messages: [e.toString()]));
    }
  }
}

/// Petite carte custom → évite complètement les overflow des ListTile
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

            // Texte
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

            // Statut + action
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
