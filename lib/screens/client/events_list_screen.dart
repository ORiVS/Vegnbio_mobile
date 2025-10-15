import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/api_result_dialogs.dart';
import '../../core/api_error.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_chip.dart';
import 'event_detail_screen.dart';
import '../auth/login_screen.dart';

class ClientEventsScreen extends ConsumerStatefulWidget {
  const ClientEventsScreen({super.key});

  @override
  ConsumerState<ClientEventsScreen> createState() => _ClientEventsScreenState();
}

class _ClientEventsScreenState extends ConsumerState<ClientEventsScreen> {
  final _queryCtrl = TextEditingController();

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // 🔒 Non connecté → UI explicite (pas d’appel réseau)
    if (!auth.isAuthenticated || auth.user == null) {
      return const _AuthRequiredView(
        title: 'Évènements',
        message: 'Vous devez être connecté pour voir vos évènements.',
      );
    }

    final async = ref.watch(eventsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Évènements',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kPrimaryGreenDark)),
            const SizedBox(height: 12),

            // petite recherche locale
            TextField(
              controller: _queryCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher un évènement…',
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: const Color(0xFFF7F7F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: async.when(
                data: (list) {
                  final q = _queryCtrl.text.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? list
                      : list.where((e) =>
                  e.title.toLowerCase().contains(q) ||
                      (e.restaurantName ?? '').toLowerCase().contains(q)).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Aucun évènement trouvé.'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(eventsProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (c, i) {
                        final ev = filtered[i];
                        final dateLine = '${ev.date}   ${_hm(ev.startTime)} – ${_hm(ev.endTime)}';

                        return InkWell(
                          onTap: () => Navigator.pushNamed(c, EventDetailScreen.route, arguments: ev.id),
                          child: Card(
                            elevation: .6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.event, color: kPrimaryGreenDark),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ev.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(ev.restaurantName ?? '—',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey.shade700)),
                                        const SizedBox(height: 6),
                                        Text(dateLine,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey.shade600)),
                                        if (ev.capacity != null) ...[
                                          const SizedBox(height: 6),
                                          _Capacity(evId: ev.id, capacity: ev.capacity!),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      StatusChip(ev.status),
                                      const SizedBox(height: 8),
                                      _ActionButton(eventId: ev.id, status: ev.status),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                // ❌ Auth error → UI explicite
                error: (e, _) {
                  if (_looksLikeAuthError(e)) {
                    return const _AuthRequiredView(
                      title: 'Évènements',
                      message: 'Vous devez être connecté pour voir vos évènements.',
                    );
                  }
                  return Center(child: Text('Erreur : $e'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hm(String s) => s.length >= 5 ? s.substring(0, 5) : s;
}

class _Capacity extends ConsumerWidget {
  final int evId;
  final int capacity;
  const _Capacity({required this.evId, required this.capacity});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reg = ref.watch(eventRegInfoProvider(evId));
    return reg.maybeWhen(
      data: (info) => Text('Capacité : ${info.count}/$capacity',
          style: TextStyle(color: Colors.grey.shade700)),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final int eventId;
  final String status;
  const _ActionButton({required this.eventId, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reg = ref.watch(eventRegInfoProvider(eventId));

    if (status != 'PUBLISHED') {
      return const SizedBox.shrink();
    }

    return reg.when(
      data: (info) {
        final meIn = info.meRegistered;
        if (meIn) {
          return SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: () => _unregister(context, ref),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: BorderSide(color: Colors.red.shade200),
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text('Se désinscrire', style: TextStyle(fontSize: 12)),
            ),
          );
        } else {
          return SizedBox(
            height: 32,
            child: FilledButton(
              onPressed: () => _register(context, ref),
              style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
              child: const Text('S’inscrire', style: TextStyle(fontSize: 12)),
            ),
          );
        }
      },
      loading: () => const SizedBox(
        height: 32, width: 32, child: Center(child: SizedBox(width: 16,height: 16,child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _register(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(context, title: 'S’inscrire à cet évènement ?', confirmLabel: 'S’inscrire');
    if (ok != true) return;

    final err = await registerToEvent(eventId);
    if (err != null) {
      if (_apiErrLooksLikeAuth(err)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const _AuthRequiredView(
              title: 'Évènements',
              message: 'Vous devez être connecté pour voir vos évènements.',
            ),
          ),
        );
        return;
      }
      await showErrorDialog(context, title: 'Inscription impossible.', error: err);
      return;
    }
    await showSuccessDialog(context, title: 'Inscription confirmée.');
    ref.invalidate(eventRegInfoProvider(eventId));
    ref.invalidate(eventsProvider);
  }

  Future<void> _unregister(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(context, title: 'Se désinscrire ?', confirmLabel: 'Oui, me désinscrire');
    if (ok != true) return;

    final err = await unregisterFromEvent(eventId);
    if (err != null) {
      if (_apiErrLooksLikeAuth(err)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const _AuthRequiredView(
              title: 'Évènements',
              message: 'Vous devez être connecté pour voir vos évènements.',
            ),
          ),
        );
        return;
      }
      await showErrorDialog(context, title: 'Désinscription impossible.', error: err);
      return;
    }
    await showSuccessDialog(context, title: 'Désinscription effectuée.');
    ref.invalidate(eventRegInfoProvider(eventId));
    ref.invalidate(eventsProvider);
  }
}

/// UI dédiée “connexion nécessaire”
class _AuthRequiredView extends StatelessWidget {
  final String title;
  final String message;
  const _AuthRequiredView({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: kPrimaryGreenDark)),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 42, color: kPrimaryGreenDark),
                    const SizedBox(height: 10),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(context, LoginScreen.route),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _looksLikeAuthError(Object e) {
  if (e is DioException) {
    if (e.response?.statusCode == 401) return true;
    if (e.type == DioExceptionType.cancel && (e.error?.toString() == 'auth_required')) return true;
  }
  return false;
}

bool _apiErrLooksLikeAuth(ApiError err) {
  // Messages retournés par ApiError.fromDio sur 401/guard
  final txt = err.messages.join(' ').toLowerCase();
  return txt.contains('authent') || txt.contains('401') || txt.contains('connect');
}
