// lib/screens/restaurateur/resto_reservations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reservations_provider.dart';
import '../../providers/restaurants_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/status_chip.dart';
import '../../core/api_error.dart';
import '../../widgets/api_result_dialogs.dart';

class RestoReservationsScreen extends ConsumerWidget {
  static const route = '/r/reservations';
  const RestoReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final restoId = user.activeRestaurantId ?? (user.restaurants.isNotEmpty ? user.restaurants.first.id : null);

    if (restoId == null) {
      return const Scaffold(body: Center(child: Text('Aucun restaurant associé')));
    }

    final async = ref.watch(restoReservationsProvider(restoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Réservations')),
      body: async.when(
        data: (list) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (c, i) {
            final r = list[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.event_note),
                title: Text(r.roomName ?? r.restaurantName ?? 'Réservation'),
                subtitle: Text('${r.date} ${_hm(r.startTime)}–${_hm(r.endTime)} • ${r.fullRestaurant ? 'Restaurant entier' : 'Salle à affecter'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(r.status),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (v) async {
                        if (v == 'assign') {
                          await _openAssignSheet(context, ref, restoId, r.id);
                          ref.invalidate(restoReservationsProvider(restoId));
                          return;
                        }
                        final err = await moderateReservation(r.id, v);
                        if (context.mounted) {
                          if (err == null) {
                            await showSuccessDialog(context, title: 'Statut mis à jour.');
                            ref.invalidate(restoReservationsProvider(restoId));
                          } else {
                            await showErrorDialog(context, title: 'Action impossible', error: err);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'CONFIRMED', child: Text('Confirmer')),
                        const PopupMenuItem(value: 'CANCELLED', child: Text('Annuler')),
                        const PopupMenuItem(value: 'assign', child: Text('Assigner…')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  String _hm(String s) => s.length >= 5 ? s.substring(0, 5) : s;

  Future<void> _openAssignSheet(
      BuildContext context,
      WidgetRef ref,
      int restaurantId,
      int reservationId,
      ) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final roomsAsync = ref.watch(restaurantDetailProvider(restaurantId));
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: roomsAsync.when(
            data: (resto) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.store_mall_directory),
                  title: const Text('Réserver tout le restaurant'),
                  onTap: () async {
                    final err = await assignReservationAsFull(reservationId);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (err == null) {
                      await showSuccessDialog(context, title: 'Assignation effectuée (restaurant entier).');
                    } else {
                      await showErrorDialog(context, title: 'Assignation impossible', error: err);
                    }
                  },
                ),
                const Divider(),
                ...resto.rooms.map((room) => ListTile(
                  leading: const Icon(Icons.meeting_room_outlined),
                  title: Text('${room.name} • ${room.capacity} places'),
                  onTap: () async {
                    final err = await assignReservationToRoom(
                      reservationId: reservationId,
                      roomId: room.id,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (err == null) {
                      await showSuccessDialog(context, title: 'Salle assignée avec succès.');
                    } else {
                      await showErrorDialog(context, title: 'Assignation impossible', error: err);
                    }
                  },
                )),
                const SizedBox(height: 10),
              ],
            ),
            loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SizedBox(
              height: 140,
              child: Center(child: Text('Erreur: $e')),
            ),
          ),
        );
      },
    );
  }
}
