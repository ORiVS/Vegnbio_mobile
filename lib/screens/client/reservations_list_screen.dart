import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reservations_provider.dart';
import '../../widgets/status_chip.dart';

class ClientReservationsScreen extends ConsumerWidget {
  static const route = '/c/reservations';
  const ClientReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myReservationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes réservations')),
      body: async.when(
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('Aucune réservation'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (c, i) {
              final r = list[i];
              final title = r.fullRestaurant
                  ? (r.restaurantName ?? 'Restaurant')
                  : (r.roomName ?? 'Salle');
              final subtitle = r.fullRestaurant && r.restaurantName != null
                  ? 'Restaurant entier'
                  : (r.restaurantName ?? '');

              return Card(
                elevation: 0.4,
                child: ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text(title),
                  subtitle: Text('$subtitle\n${r.date} ${r.startTime.substring(0,5)} - ${r.endTime.substring(0,5)}'),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatusChip(r.status),
                      if (r.status == 'PENDING')
                        TextButton(
                          onPressed: () async {
                            final err = await cancelReservation(r.id);
                            if (err != null) {
                              ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(err)));
                            } else {
                              ref.invalidate(myReservationsProvider);
                            }
                          },
                          child: const Text('Annuler'),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
