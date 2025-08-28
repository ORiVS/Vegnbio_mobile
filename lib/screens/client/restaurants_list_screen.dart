import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/restaurants_provider.dart';
import '../../widgets/primary_cta.dart';
import 'restaurant_detail_screen.dart';

class ClientRestaurantsScreen extends ConsumerWidget {
  static const route = '/c/restaurants';
  const ClientRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find The Best Food Around You', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.tune))],
      ),
      body: async.when(
        data: (list) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (c, i) {
            final r = list[i];
            return InkWell(
              onTap: () => Navigator.pushNamed(c, ClientRestaurantDetailScreen.route, arguments: r.id),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 28, child: Text(r.name.isEmpty ? '?' : r.name[0])),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(r.city, style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6, runSpacing: -6,
                            children: [
                              if (r.wifi) _chip('Wifi'),
                              if (r.printer) _chip('Printer'),
                              if (r.animationsEnabled) _chip('Animations'),
                            ],
                          ),
                        ]),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: list.length,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _chip(String label) => Chip(label: Text(label));
}
