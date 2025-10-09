// lib/screens/client/restaurant_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegnbio_app/screens/client/restaurant_menu_screen.dart';
import '../../providers/restaurants_provider.dart';
import '../../providers/menu_providers.dart';
import '../../widgets/primary_cta.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/dish_tile.dart';
import '../../theme/app_colors.dart';
import '../../models/restaurant.dart';
import '../../models/menu.dart';
import '../../models/dish.dart';
import 'dish_detail_screen.dart';
import 'reservation_new_screen.dart';

class ClientRestaurantDetailScreen extends ConsumerStatefulWidget {
  static const route = '/c/restaurant';
  const ClientRestaurantDetailScreen({super.key});

  @override
  ConsumerState<ClientRestaurantDetailScreen> createState() => _ClientRestaurantDetailScreenState();
}

class _ClientRestaurantDetailScreenState extends ConsumerState<ClientRestaurantDetailScreen> {
  bool _showHours = false;
  int _dayOffset = 0; // 0 = aujourd’hui, 1 = demain

  String _dateForOffset(int offset) {
    final d = DateTime.now().add(Duration(days: offset));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final async = ref.watch(restaurantDetailProvider(id));

    return Scaffold(
      appBar: AppBar(leading: const BackButton(color: Colors.black), backgroundColor: Colors.white, elevation: 0),
      body: async.when(
        data: (r) {
          final openNow = _isOpenNow(r, DateTime.now());
          final dateStr = _dateForOffset(_dayOffset);

          final key = (restaurantId: r.id, date: dateStr);
          final menusAsync = ref.watch(menusWithDishesProvider(key));
          final unavailableAsync = ref.watch(unavailableDishIdsProvider(key));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- En-tête ---
              Text(r.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: Text('${r.city} • ${r.capacity} places', style: TextStyle(color: Colors.grey.shade700))),
                  _OpenBadge(isOpen: openNow),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _showHours = !_showHours),
                    child: Row(
                      children: [
                        Text('Horaires', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        Icon(_showHours ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey.shade700),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _HoursBlock(r: r),
                crossFadeState: _showHours ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),

              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    ClientRestaurantMenuScreen.route,
                    arguments: {
                      'restaurantId': r.id,
                      'restaurantName': r.name, // optionnel
                    },
                  );
                },
                child: const Text('Voir le menu'),
              ),
              const SizedBox(height: 18),

              // --- Services ---
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
              ..._roomsWithSpacing(context, r),

              const SizedBox(height: 12),
              PrimaryCta(
                text: 'Faire une réservation',
                onPressed: () {
                  Navigator.pushNamed(context, ClientReservationNewScreen.route, arguments: {
                    'restaurantId': r.id,
                    'roomId': null,
                    'full': true,
                  });
                },
              ),

              // (Exemple si tu veux afficher le menu ici)
              // menusAsync.when(
              //   data: (menu) => unavailableAsync.when(
              //     data: (unavailable) => Column(
              //       children: _buildCourseSections(context, r, menu, unavailable, dateStr),
              //     ),
              //     loading: () => const SizedBox.shrink(),
              //     error: (_, __) => const SizedBox.shrink(),
              //   ),
              //   loading: () => const SizedBox.shrink(),
              //   error: (_, __) => const SizedBox.shrink(),
              // ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  List<Widget> _buildCourseSections(
      BuildContext context,
      Restaurant r,
      Menu menu,
      Set<int> unavailableIds,
      String dateStr,
      ) {
    List<Widget> section(String label, CourseType ct) {
      final items = menu.items.where((it) => it.course == ct && (it.dish != null)).toList();
      if (items.isEmpty) return [];
      return [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        ...items.map((it) {
          final d = it.dish!;
          final un = unavailableIds.contains(d.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DishTile(
              dish: d,
              unavailable: un,
              onTap: () => Navigator.pushNamed(
                context,
                DishDetailScreen.route,
                arguments: {
                  'dish': d,
                  'restaurantId': r.id,     // ✅ on passe depuis le restaurant courant
                  'restaurantName': r.name, // (optionnel, pour l’UI)
                  'date': dateStr,          // ✅ jour affiché
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
      ];
    }

    return [
      ...section('Entrées', CourseType.entree),
      ...section('Plats', CourseType.plat),
      ...section('Desserts', CourseType.dessert),
      ...section('Boissons', CourseType.boisson),
    ];
  }

  // ---- Salles + Helpers existants ----
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
        children.add(const SizedBox(height: 10));
      }
    }
    if (children.isEmpty) {
      children.add(Text('Aucune salle listée.', style: TextStyle(color: Colors.grey.shade600)));
    }
    return children;
  }

  bool _isOpenNow(Restaurant r, DateTime now) {
    int _mm(String hhmmss) {
      final p = hhmmss.split(':');
      final h = int.tryParse(p[0]) ?? 0;
      final m = int.tryParse(p[1]) ?? 0;
      return h * 60 + m;
    }
    (int open, int close) _timesFor(int wd) {
      if (wd >= 0 && wd <= 3) return (_mm(r.openingTimeMonToThu), _mm(r.closingTimeMonToThu));
      if (wd == 4) return (_mm(r.openingTimeFriday), _mm(r.closingTimeFriday));
      if (wd == 5) return (_mm(r.openingTimeSaturday), _mm(r.closingTimeSaturday));
      return (_mm(r.openingTimeSunday), _mm(r.closingTimeSunday));
    }

    final local = now;
    final wd = (local.weekday + 6) % 7;
    final minutesNow = local.hour * 60 + local.minute;
    final (openT, closeT) = _timesFor(wd);

    bool inSame(int o, int c, int n) => (c > o) ? (n >= o && n <= c) : (n >= o);
    final okToday = inSame(openT, closeT, minutesNow);

    (int, int) _prev(int wd0) {
      final prev = (wd0 - 1) % 7;
      if (prev >= 0 && prev <= 3) return (_mm(r.openingTimeMonToThu), _mm(r.closingTimeMonToThu));
      if (prev == 4) return (_mm(r.openingTimeFriday), _mm(r.closingTimeFriday));
      if (wd0 == 5) return (_mm(r.openingTimeSaturday), _mm(r.closingTimeSaturday));
      return (_mm(r.openingTimeSunday), _mm(r.closingTimeSunday));
    }
    final (pO, pC) = _prev(wd);
    final prevOver = pC <= pO;
    final okPrevSpill = prevOver && (minutesNow <= pC);
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

  String _fmt(String s) => s.substring(0, 5);
  Widget _row(String label, String open, String close) => Row(
    children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
      Expanded(child: Text('${_fmt(open)} – ${_fmt(close)}')),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(top: 8, bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF7F7F8), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        _row('Lun–Jeu', r.openingTimeMonToThu, r.closingTimeMonToThu),
        const SizedBox(height: 6),
        _row('Vendredi', r.openingTimeFriday, r.closingTimeFriday),
        const SizedBox(height: 6),
        _row('Samedi', r.openingTimeSaturday, r.closingTimeSaturday),
        const SizedBox(height: 6),
        _row('Dimanche', r.openingTimeSunday, r.closingTimeSunday),
      ]),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  final int dayOffset;
  final ValueChanged<int> onChange;
  const _MenuHeader({required this.dayOffset, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final selected0 = dayOffset == 0;
    final selected1 = dayOffset == 1;

    Widget pill(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: Material(
          color: selected ? kPrimaryGreen : const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(label, style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w700,
                )),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            pill('Aujourd’hui', selected0, () => onChange(0)),
            const SizedBox(width: 8),
            pill('Demain', selected1, () => onChange(1)),
          ],
        ),
      ],
    );
  }
}
