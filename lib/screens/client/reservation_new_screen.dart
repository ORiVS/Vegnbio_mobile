import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/restaurants_provider.dart';
import '../../providers/reservations_provider.dart';
import '../../widgets/primary_cta.dart';

class ClientReservationNewScreen extends ConsumerStatefulWidget {
  static const route = '/c/reservation/new';
  const ClientReservationNewScreen({super.key});
  @override
  ConsumerState<ClientReservationNewScreen> createState() => _ClientReservationNewScreenState();
}

class _ClientReservationNewScreenState extends ConsumerState<ClientReservationNewScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _start = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 14, minute: 0);
  bool _full = false;
  int? _restaurantId;
  int? _roomId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)!.settings.arguments as Map?) ?? {};
    _restaurantId = args['restaurantId'] as int?;
    _roomId = args['roomId'] as int?;
    _full = (args['full'] as bool?) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final restAsync = _restaurantId != null ? ref.watch(restaurantDetailProvider(_restaurantId!)) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle réservation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (restAsync != null) ...[
              restAsync.when(
                data: (r) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('Réserver tout le restaurant'),
                      value: _full,
                      onChanged: (v) => setState(() => _full = v),
                    ),
                    if (!_full)
                      DropdownButtonFormField<int>(
                        value: _roomId,
                        validator: (_) => _roomId == null ? 'Choisissez une salle' : null,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.meeting_room), hintText: 'Salle'),
                        items: r.rooms.map((room) => DropdownMenuItem(value: room.id, child: Text(room.name))).toList(),
                        onChanged: (v) => setState(() => _roomId = v),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Erreur: $e'),
              ),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text('${_date.year}-${_two(_date.month)}-${_two(_date.day)}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: 8),
            _timeTile('Heure de début', _start, (t) => setState(() => _start = t)),
            _timeTile('Heure de fin', _end, (t) => setState(() => _end = t)),
            const SizedBox(height: 16),
            PrimaryCta(
              text: 'Confirmer',
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final err = await createReservation(
                  restaurantId: _restaurantId,
                  roomId: _roomId,
                  date: '${_date.year}-${_two(_date.month)}-${_two(_date.day)}',
                  startTime: '${_two(_start.hour)}:${_two(_start.minute)}',
                  endTime: '${_two(_end.hour)}:${_two(_end.minute)}',
                  fullRestaurant: _full,
                );
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Réservation créée ✅')));
                    Navigator.pop(context);
                  }
                }
              },
            )
          ]),
        ),
      ),
    );
  }

  Widget _timeTile(String label, TimeOfDay value, ValueChanged<TimeOfDay> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.access_time),
      title: Text('$label: ${_two(value.hour)}:${_two(value.minute)}'),
      trailing: const Icon(Icons.edit),
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: value);
        if (t != null) onChanged(t);
      },
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
