// lib/screens/client/reservation_new_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_error.dart';
import '../../providers/reservations_provider.dart';
import '../../providers/restaurants_provider.dart';
import '../../widgets/api_result_dialogs.dart';
import '../../theme/app_colors.dart';
import '../../models/restaurant.dart';
import 'client_shell.dart';

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
  int _partySize = 2;
  bool _loading = false;

  int? restaurantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    restaurantId = args?['restaurantId'] as int?;
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
    final init = start
        ? (_start ?? const TimeOfDay(hour: 12, minute: 0))
        : (_end ?? const TimeOfDay(hour: 14, minute: 0));
    final t = await showTimePicker(context: context, initialTime: init);
    if (t != null) setState(() => start ? _start = t : _end = t);
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ---- Validation locale vs horaires du jour sélectionné ----
  ({TimeOfDay open, TimeOfDay close, bool overnight}) _hoursFor(Restaurant r, DateTime day) {
    TimeOfDay _toTod(String hhmmss) {
      final p = hhmmss.split(':');
      return TimeOfDay(hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p[1]) ?? 0);
    }

    final wd = (day.weekday + 6) % 7; // 0=Mon .. 6=Sun
    if (wd >= 0 && wd <= 3) {
      return (open: _toTod(r.openingTimeMonToThu), close: _toTod(r.closingTimeMonToThu),
      overnight: _isOvernight(r.openingTimeMonToThu, r.closingTimeMonToThu));
    } else if (wd == 4) {
      return (open: _toTod(r.openingTimeFriday), close: _toTod(r.closingTimeFriday),
      overnight: _isOvernight(r.openingTimeFriday, r.closingTimeFriday));
    } else if (wd == 5) {
      return (open: _toTod(r.openingTimeSaturday), close: _toTod(r.closingTimeSaturday),
      overnight: _isOvernight(r.openingTimeSaturday, r.closingTimeSaturday));
    } else {
      return (open: _toTod(r.openingTimeSunday), close: _toTod(r.closingTimeSunday),
      overnight: _isOvernight(r.openingTimeSunday, r.closingTimeSunday));
    }
  }

  bool _isOvernight(String open, String close) {
    final o = int.parse(open.substring(0,2)) * 60 + int.parse(open.substring(3,5));
    final c = int.parse(close.substring(0,2)) * 60 + int.parse(close.substring(3,5));
    return c <= o; // fermeture le “lendemain”
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _submit() async {
    if (restaurantId == null) {
      await showErrorDialog(context, error: ApiError(messages: ["Restaurant manquant."]));
      return;
    }
    if (_start == null || _end == null) {
      await showErrorDialog(context, error: ApiError(messages: ["Choisissez une heure de début et une heure de fin."]));
      return;
    }
    if (_partySize <= 0) {
      await showErrorDialog(context, error: ApiError(messages: ["Le nombre de couverts doit être supérieur à 0."]));
      return;
    }

    // Pré-validation locale des horaires
    final restoAsync = ref.read(restaurantDetailProvider(restaurantId!).future);
    final r = await restoAsync;
    final hours = _hoursFor(r, _date);

    final s = _toMinutes(_start!);
    final e = _toMinutes(_end!);
    final o = _toMinutes(hours.open);
    final c = _toMinutes(hours.close);

    bool ok;
    if (!hours.overnight) {
      ok = s >= o && e <= c && s < e;
    } else {
      // overnight: ex 09:00 -> 05:00 (lendemain)
      // On autorise sur la journée sélectionnée uniquement la partie [open..23:59]
      ok = (s >= o && s < 24*60) && (e > 0 && e <= 24*60) && (s < e);
      // NOTE: si tu veux autoriser un créneau allant après minuit (jour+1),
      // il faudra décider UX (sélection multi-jour). Ici on reste simple.
    }

    if (!ok) {
      await showErrorDialog(
        context,
        title: 'Créneau hors horaires',
        error: ApiError(messages: [
          "Le créneau choisi ne correspond pas aux horaires du jour sélectionné.",
          "Horaires : ${_fmtTime(hours.open)} – ${_fmtTime(hours.close)}"
        ]),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final err = await createReservation(
        restaurantId: restaurantId!,
        date: _fmtDate(_date),
        startTime: _fmtTime(_start!),
        endTime: _fmtTime(_end!),
        partySize: _partySize,
      );

      if (!mounted) return;
      if (err == null) {
        await showSuccessDialog(
          context,
          title: 'Demande envoyée',
          messages: [
            'Votre réservation est enregistrée en attente.',
            'Le restaurateur vous confirmera le créneau rapidement.',
            'Résumé : ${_fmtDate(_date)} ${_fmtTime(_start!)} → ${_fmtTime(_end!)}, $_partySize couverts.',
          ],
          primaryLabel: 'Voir mes réservations',
          onPrimary: () {
            Navigator.pushReplacementNamed(context, ClientShell.route, arguments: {'tab': 1});
          },
          secondaryLabel: 'Fermer',
          onSecondary: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        );
      } else {
        await showErrorDialog(context, title: 'Réservation impossible.', error: err);
      }
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
    final title = 'Nouvelle réservation';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: restaurantId == null
          ? const Center(child: Text('Restaurant manquant'))
          : Consumer(
        builder: (ctx, ref, _) {
          final restoAsync = ref.watch(restaurantDetailProvider(restaurantId!));
          return restoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (r) {
              final hours = _hoursFor(r, _date);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Note UX
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFE3CD)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Color(0xFF2F7B57)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Votre demande sera d’abord en attente (PENDING). "
                                "Le restaurateur confirmera votre créneau et affectera une salle si nécessaire.",
                            style: TextStyle(height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  _InfoRow(icon: Icons.store_mall_directory, label: 'Restaurant', value: '${r.name} — ${r.city}'),

                  const SizedBox(height: 16),
                  const Text('Date', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _BoxButton(
                    onTap: _pickDate,
                    child: Row(
                      children: [const Icon(Icons.event), const SizedBox(width: 10), Text(_fmtDate(_date))],
                    ),
                  ),

                  const SizedBox(height: 10),
                  _HoursHint(hours: hours),

                  const SizedBox(height: 16),
                  const Text('Heure de début', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _BoxButton(
                    onTap: () => _pickTime(start: true),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 10),
                        Text(_start == null ? 'Choisir…' : _fmtTime(_start!)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Heure de fin', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _BoxButton(
                    onTap: () => _pickTime(start: false),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 10),
                        Text(_end == null ? 'Choisir…' : _fmtTime(_end!)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Nombre de couverts', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _PartySizeStepper(
                    value: _partySize,
                    onChanged: (v) => setState(() => _partySize = v),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Envoyer la demande'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HoursHint extends StatelessWidget {
  final ({TimeOfDay open, TimeOfDay close, bool overnight}) hours;
  const _HoursHint({required this.hours});

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final text = 'Horaires ce jour : ${_fmt(hours.open)} – ${_fmt(hours.close)}'
        '${hours.overnight ? " (fermeture le lendemain)" : ""}';
    return Row(
      children: [
        const Icon(Icons.schedule, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700))),
      ],
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

class _PartySizeStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _PartySizeStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onChanged(value > 1 ? value - 1 : 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
