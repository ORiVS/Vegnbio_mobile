import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/status_chip.dart';

class RestoDashboardScreen extends ConsumerStatefulWidget {
  static const route = '/r/dashboard';
  const RestoDashboardScreen({super.key});

  @override
  ConsumerState<RestoDashboardScreen> createState() => _RestoDashboardScreenState();
}

class _RestoDashboardScreenState extends ConsumerState<RestoDashboardScreen> {
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final restoId = user.activeRestaurantId ?? (user.restaurants.isNotEmpty ? user.restaurants.first.id : null);

    if (restoId == null) {
      return const Scaffold(body: Center(child: Text('Aucun restaurant associé')));
    }

    final async = ref.watch(dashboardProvider((restaurantId: restoId, date: _d(_date))));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
        ],
      ),
      body: async.when(
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${d.restaurant} — ${d.date}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            const Text('Salles', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...d.rooms.map((r) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${r.room} • ${r.capacity} places', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  if (r.reservations.isEmpty)
                    Text('Aucun créneau', style: TextStyle(color: Colors.grey.shade600))
                  else
                    Wrap(
                      spacing: 8,
                      children: r.reservations
                          .map((rv) => Chip(
                        label: Text('${rv.startTime.substring(0,5)}–${rv.endTime.substring(0,5)}'),
                        avatar: CircleAvatar(radius: 6, backgroundColor: _statusColor(rv.status)),
                      ))
                          .toList(),
                    ),
                ]),
              ),
            )),
            const SizedBox(height: 10),
            const Text('Évènements', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (d.events.isEmpty)
              Text('Aucun évènement', style: TextStyle(color: Colors.grey.shade600))
            else
              ...d.events.map((e) => ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: Text(e.title),
                subtitle: Text('${e.type} • ${e.startTime.substring(0,5)}–${e.endTime.substring(0,5)}'),
                trailing: StatusChip(e.status),
              )),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  String _d(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  Color _statusColor(String s) {
    switch (s) {
      case 'CONFIRMED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
