import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/restaurants_provider.dart';
import '../../widgets/primary_cta.dart';
import '../../widgets/status_chip.dart';
import 'reservation_new_screen.dart';

class ClientRestaurantDetailScreen extends ConsumerWidget {
  static const route = '/c/restaurant';
  const ClientRestaurantDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final async = ref.watch(restaurantDetailProvider(id));

    return Scaffold(
      appBar: AppBar(leading: BackButton(color: Colors.black), backgroundColor: Colors.white, elevation: 0),
      body: async.when(
        data: (r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(r.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('${r.city} • ${r.capacity} places', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, children: [
              if (r.wifi) const StatusChip('WIFI'),
              if (r.printer) const StatusChip('PRINTER'),
              if (r.deliveryTrays) const StatusChip('Delivery trays'),
              if (r.animationsEnabled) StatusChip('Animations ${r.animationDay ?? ""}'),
            ]),
            const SizedBox(height: 18),
            const Text('Salles', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...r.rooms.map((room) => Card(
              elevation: 0.4,
              child: ListTile(
                title: Text(room.name),
                subtitle: Text('Capacité ${room.capacity}'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, ClientReservationNewScreen.route,
                      arguments: {'restaurantId': r.id, 'roomId': room.id});
                },
              ),
            )),
            const SizedBox(height: 12),
            PrimaryCta(
              text: 'Réserver le restaurant entier',
              onPressed: () {
                Navigator.pushNamed(context, ClientReservationNewScreen.route,
                    arguments: {'restaurantId': r.id, 'roomId': null, 'full': true});
              },
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
