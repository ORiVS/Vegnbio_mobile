// lib/screens/client/restaurant_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/restaurants_provider.dart';
import '../../widgets/primary_cta.dart';
import '../../widgets/status_chip.dart';
import '../../theme/app_colors.dart';
import '../../models/restaurant.dart';
import 'reservation_new_screen.dart';

class ClientRestaurantDetailScreen extends ConsumerStatefulWidget {
  static const route = '/c/restaurant';
  const ClientRestaurantDetailScreen({super.key});

  @override
  ConsumerState<ClientRestaurantDetailScreen> createState() => _ClientRestaurantDetailScreenState();
}

class _ClientRestaurantDetailScreenState extends ConsumerState<ClientRestaurantDetailScreen> {
  bool _showHours = false;

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final async = ref.watch(restaurantDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: async.when(
        data: (r) {
          final openNow = _isOpenNow(r, DateTime.now());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(r.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${r.city} • ${r.capacity} places',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  _OpenBadge(isOpen: openNow),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _showHours = !_showHours),
                    child: Row(
                      children: [
                        Text('Horaires', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Icon(_showHours ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey.shade700),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bloc horaires (toggle)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _HoursBlock(r: r),
                crossFadeState: _showHours ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
              const SizedBox(height: 14),

              // Services
              Wrap(spacing: 8, runSpacing: -6, children: [
                if (r.wifi) const StatusChip('Wifi'),
                if (r.printer) const StatusChip('Imprimante'),
                if (r.deliveryTrays) const StatusChip('Plateaux livrables'),
                if (r.memberTrays) const StatusChip('Plateaux membres'),
                if (r.animationsEnabled) StatusChip('Animations ${r.animationDay ?? ""}'),
              ]),
              const SizedBox(height: 18),

              const Text('Salles', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              // Espacement entre chaque salle
              ..._roomsWithSpacing(context, r),

              const SizedBox(height: 12),
              PrimaryCta(
                text: 'Réserver le restaurant entier',
                onPressed: () {
                  Navigator.pushNamed(context, ClientReservationNewScreen.route, arguments: {
                    'restaurantId': r.id,
                    'roomId': null,
                    'full': true,
                  });
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  // ------ helpers UI ------

  List<Widget> _roomsWithSpacing(BuildContext context, Restaurant r) {
    final children = <Widget>[];
    for (var i = 0; i < r.rooms.length; i++) {
      final room = r.rooms[i];
      children.add(Card(
        elevation: 0.4,
        child: ListTile(
          title: Text(room.name),
          subtitle: Text('Capacité ${room.capacity}'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () {
            Navigator.pushNamed(context, ClientReservationNewScreen.route, arguments: {
              'restaurantId': r.id,
              'roomId': room.id,
              'full': false,
            });
          },
        ),
      ));
      if (i != r.rooms.length - 1) {
        children.add(const SizedBox(height: 10)); // ← espace entre salles
      }
    }
    if (children.isEmpty) {
      children.add(Text('Aucune salle listée.', style: TextStyle(color: Colors.grey.shade600)));
    }
    return children;
  }

  // ------ logique horaires / ouvert-fermé ------

  bool _isOpenNow(Restaurant r, DateTime now) {
    // minute depuis minuit
    int _mm(String hhmmss) {
      final p = hhmmss.split(':');
      final h = int.tryParse(p[0]) ?? 0;
      final m = int.tryParse(p[1]) ?? 0;
      return h * 60 + m;
    }

    // Sélectionne l'horaire du jour
    (int open, int close) _todayTimes(int wd) {
      // 0 = lundi ... 6 = dimanche
      if (wd >= 0 && wd <= 3) {
        return (_mm(r.openingTimeMonToThu), _mm(r.closingTimeMonToThu));
      } else if (wd == 4) {
        return (_mm(r.openingTimeFriday), _mm(r.closingTimeFriday));
      } else if (wd == 5) {
        return (_mm(r.openingTimeSaturday), _mm(r.closingTimeSaturday));
      } else {
        return (_mm(r.openingTimeSunday), _mm(r.closingTimeSunday));
      }
    }

    final local = now; // on prend l'heure locale du device
    final wd = (local.weekday + 6) % 7; // Dart: Mon=1..Sun=7 → 0..6
    final minutesNow = local.hour * 60 + local.minute;

    final (openT, closeT) = _todayTimes(wd);

    bool inSameDay(int open, int close, int nowM) {
      if (close > open) {
        return nowM >= open && nowM <= close;
      } else {
        // overnight (ex: 20:00 - 02:00)
        return nowM >= open; // après open jusqu'à minuit
      }
    }

    var okToday = inSameDay(openT, closeT, minutesNow);

    // cas "spill" après minuit couvert par la veille (overnight)
    (int, int) _prevTimes(int wd0) {
      final prev = (wd0 - 1) % 7;
      if (prev >= 0 && prev <= 3) return (_mm(r.openingTimeMonToThu), _mm(r.closingTimeMonToThu));
      if (prev == 4) return (_mm(r.openingTimeFriday), _mm(r.closingTimeFriday));
      if (prev == 5) return (_mm(r.openingTimeSaturday), _mm(r.closingTimeSaturday));
      return (_mm(r.openingTimeSunday), _mm(r.closingTimeSunday));
    }

    final (prevOpen, prevClose) = _prevTimes(wd);
    final prevOvernight = prevClose <= prevOpen;
    final okPrevSpill = prevOvernight && (minutesNow <= prevClose);

    return okToday || okPrevSpill;
  }
}

class _OpenBadge extends StatelessWidget {
  final bool isOpen;
  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? kPrimaryGreenDark : Colors.red.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(isOpen ? 'Ouvert' : 'Fermé', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _HoursBlock extends StatelessWidget {
  final Restaurant r;
  const _HoursBlock({required this.r});

  String _fmt(String s) {
    final hhmm = s.substring(0, 5); // "HH:MM"
    return hhmm;
  }

  Widget _row(String label, String open, String close) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text('${_fmt(open)} – ${_fmt(close)}')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row('Lun–Jeu', r.openingTimeMonToThu, r.closingTimeMonToThu),
          const SizedBox(height: 6),
          _row('Vendredi', r.openingTimeFriday, r.closingTimeFriday),
          const SizedBox(height: 6),
          _row('Samedi', r.openingTimeSaturday, r.closingTimeSaturday),
          const SizedBox(height: 6),
          _row('Dimanche', r.openingTimeSunday, r.closingTimeSunday),
        ],
      ),
    );
  }
}
