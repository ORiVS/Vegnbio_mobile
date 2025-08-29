// lib/screens/client/reservation_new_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_paths.dart';
import '../../core/api_service.dart';
import '../../core/api_error.dart';
import '../../widgets/api_result_dialogs.dart';
import '../../theme/app_colors.dart';
import 'client_shell.dart';
import 'reservations_list_screen.dart';

class ClientReservationNewScreen extends ConsumerStatefulWidget {
  static const route = '/c/reservation/new';
  const ClientReservationNewScreen({super.key});

  @override
  ConsumerState<ClientReservationNewScreen> createState() => _ClientReservationNewScreenState();
}

class _ClientReservationNewScreenState extends ConsumerState<ClientReservationNewScreen> {
  DateTime _date = DateTime.now();
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _loading = false;

  int? restaurantId;
  int? roomId;
  bool full = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    restaurantId = args?['restaurantId'] as int?;
    roomId = args?['roomId'] as int?;
    full = (args?['full'] as bool?) ?? false;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime({required bool start}) async {
    final init = start ? (_start ?? const TimeOfDay(hour: 12, minute: 0)) : (_end ?? const TimeOfDay(hour: 14, minute: 0));
    final t = await showTimePicker(context: context, initialTime: init);
    if (t != null) setState(() => start ? _start = t : _end = t);
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:00';

  Future<void> _submit() async {
    if (restaurantId == null) {
      await showErrorDialog(context, error: ApiError(messages: ["Restaurant manquant."]));
      return;
    }
    if (!full && roomId == null) {
      await showErrorDialog(context, error: ApiError(messages: ["Veuillez choisir une salle ou sélectionnez “restaurant entier”."]));
      return;
    }
    if (_start == null || _end == null) {
      await showErrorDialog(context, error: ApiError(messages: ["Veuillez choisir une heure de début et de fin."]));
      return;
    }

    setState(() => _loading = true);
    try {
      final payload = {
        'restaurant': restaurantId,
        'room': full ? null : roomId,
        'full_restaurant': full,
        'date': _fmtDate(_date),
        'start_time': _fmtTime(_start!),
        'end_time': _fmtTime(_end!),
      };

      final res = await ApiService.instance.dio.post(ApiPaths.reservations, data: payload);

      if (!mounted) return;
      await showSuccessDialog(
        context,
        title: 'Réservation créée.',
        messages: [
          'Date : ${payload['date']}',
          'Heure : ${payload['start_time']} → ${payload['end_time']}',
          if (!full) 'Salle #$roomId' else 'Restaurant entier',
        ],
        primaryLabel: 'OK',
        // Quand l’utilisateur veut juste fermer → on revient à l’écran précédent :
        onPrimary: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // ferme l'écran de création
          }
        },

        secondaryLabel: 'Voir mes réservations',
        onSecondary: () {
          // Remplacer l’écran courant par la liste (donc aucun pop derrière)
          Navigator.pushReplacementNamed(context, ClientShell.route, arguments: {'tab': 1});
        },
      );

    } on DioException catch (e) {
      if (!mounted) return;
      final err = ApiError.fromDio(e);
      await showErrorDialog(
        context,
        title: 'Réservation impossible.',
        error: err,
      );
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: 'Erreur inattendue.',
        error: ApiError(messages: [e.toString()]),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = full ? 'Réserver tout le restaurant' : 'Nouvelle réservation';
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!full) _InfoRow(icon: Icons.meeting_room, label: 'Salle', value: '#$roomId'),
          _InfoRow(icon: Icons.store_mall_directory, label: 'Restaurant', value: '#$restaurantId'),

          const SizedBox(height: 16),
          const Text('Date', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _BoxButton(
            onTap: _pickDate,
            child: Row(children: [const Icon(Icons.event), const SizedBox(width: 10), Text(_fmtDate(_date))]),
          ),

          const SizedBox(height: 16),
          const Text('Heure de début', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _BoxButton(
            onTap: () => _pickTime(start: true),
            child: Row(children: [const Icon(Icons.access_time), const SizedBox(width: 10), Text(_start == null ? 'Choisir…' : _fmtTime(_start!))]),
          ),

          const SizedBox(height: 16),
          const Text('Heure de fin', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _BoxButton(
            onTap: () => _pickTime(start: false),
            child: Row(children: [const Icon(Icons.access_time), const SizedBox(width: 10), Text(_end == null ? 'Choisir…' : _fmtTime(_end!))]),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreen, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Réserver'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: kPrimaryGreenDark),
      const SizedBox(width: 10),
      Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w600)),
      Expanded(child: Text(value ?? '-', overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _BoxButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _BoxButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7F8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: child,
        ),
      ),
    );
  }
}
