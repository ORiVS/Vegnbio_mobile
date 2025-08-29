// lib/screens/client/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/events_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/api_result_dialogs.dart';
import '../../core/api_error.dart';
import '../../theme/app_colors.dart';

class EventDetailScreen extends ConsumerWidget {
  static const route = '/c/event';
  const EventDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final async = ref.watch(eventDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: async.when(
        data: (ev) {
          final dateLine = '${ev.date}   ${_hm(ev.startTime)} – ${_hm(ev.endTime)}';
          final reg = ref.watch(eventRegInfoProvider(ev.id));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: Text(ev.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
                  StatusChip(ev.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(ev.restaurantName ?? '—', style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 6),
              Text(dateLine, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 14),

              if (ev.capacity != null)
                reg.maybeWhen(
                  data: (info) => Text('Capacité : ${info.count}/${ev.capacity}',
                      style: TextStyle(color: Colors.grey.shade700)),
                  orElse: () => const SizedBox.shrink(),
                ),

              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(ev.description),

              const SizedBox(height: 24),
              _DetailAction(eventId: ev.id, status: ev.status),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }

  String _hm(String s) => s.length >= 5 ? s.substring(0, 5) : s;
}

class _DetailAction extends ConsumerWidget {
  final int eventId;
  final String status;
  const _DetailAction({required this.eventId, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (status != 'PUBLISHED') return const SizedBox.shrink();

    final reg = ref.watch(eventRegInfoProvider(eventId));
    return reg.when(
      data: (info) {
        if (info.meRegistered) {
          return FilledButton.tonal(
            onPressed: () async {
              final ok = await showConfirmDialog(context, title: 'Se désinscrire ?', confirmLabel: 'Me désinscrire');
              if (ok != true) return;
              final err = await unregisterFromEvent(eventId);
              if (err != null) { await showErrorDialog(context, title: 'Désinscription impossible.', error: err); return; }
              await showSuccessDialog(context, title: 'Désinscription effectuée.');
              ref.invalidate(eventRegInfoProvider(eventId));
              ref.invalidate(eventsProvider);
            },
            child: const Text('Se désinscrire'),
          );
        } else {
          return FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
            onPressed: () async {
              final ok = await showConfirmDialog(context, title: 'S’inscrire à cet évènement ?', confirmLabel: 'S’inscrire');
              if (ok != true) return;
              final err = await registerToEvent(eventId);
              if (err != null) { await showErrorDialog(context, title: 'Inscription impossible.', error: err); return; }
              await showSuccessDialog(context, title: 'Inscription confirmée.');
              ref.invalidate(eventRegInfoProvider(eventId));
              ref.invalidate(eventsProvider);
            },
            child: const Text('S’inscrire'),
          );
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
    );
  }
}
