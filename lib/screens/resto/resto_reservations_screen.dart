import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reservations_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/status_chip.dart';

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
                title: Text(r.roomName ?? r.restaurantName ?? 'Reservation'),
                subtitle: Text('${r.date} ${r.startTime.substring(0,5)}–${r.endTime.substring(0,5)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(r.status),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (v) async {
                        final err = await moderateReservation(r.id, v);

                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'CONFIRMED', child: Text('Confirmer')),
                        PopupMenuItem(value: 'CANCELLED', child: Text('Annuler')),
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
}
