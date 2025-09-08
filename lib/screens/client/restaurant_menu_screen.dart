import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/menu_providers.dart';
import '../../models/dish.dart';
import '../../models/menu.dart';
import '../../theme/app_colors.dart';
import '../../widgets/menu_cards.dart';
import '../../core/api_service.dart'; // adapte le chemin si besoin
import 'dish_detail_screen.dart';

// ====== Provider local : tous les plats actifs (liste ou pagination DRF) ======
final allDishesProvider = FutureProvider.family<List<Dish>, int>((ref, restaurantId) async {
  final dio = ApiService.instance.dio;
  final resp = await dio.get('/api/menu/dishes/', queryParameters: {'is_active': 'true'});
  final data = resp.data;
  final List<dynamic> raw = data is List
      ? data
      : (data is Map<String, dynamic> && data['results'] is List ? data['results'] as List : const []);
  return raw.whereType<Map<String, dynamic>>().map((m) => Dish.fromJson(m)).toList(growable: false);
});

class ClientRestaurantMenuScreen extends ConsumerStatefulWidget {
  static const route = '/c/restaurant/menu';
  const ClientRestaurantMenuScreen({super.key});

  @override
  ConsumerState<ClientRestaurantMenuScreen> createState() => _ClientRestaurantMenuScreenState();
}

enum TopTab { dishes, menus }         // <- nouveau toggle haut
enum MenuScope { today, custom }      // pour l’onglet Menus seulement

class _ClientRestaurantMenuScreenState extends ConsumerState<ClientRestaurantMenuScreen> {
  // Onglet sélectionné
  TopTab _tab = TopTab.dishes;

  // Portée de date (uniquement onglet Menus)
  MenuScope _scope = MenuScope.today;
  DateTime? _customDay;
  DateTimeRange? _customRange;

  // Recherche (uniquement onglet Plats)
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Utils
  String _yyyyMmDd(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  Iterable<DateTime> _daysInRange(DateTime start, DateTime end) sync* {
    var d = DateUtils.dateOnly(start);
    final last = DateUtils.dateOnly(end);
    while (!d.isAfter(last)) {
      yield d;
      d = d.add(const Duration(days: 1));
    }
  }

  List<DateTime> _datesToLoad() {
    if (_scope == MenuScope.today) return [_today];
    if (_customDay != null) return [DateUtils.dateOnly(_customDay!)];
    if (_customRange != null) {
      return _daysInRange(_customRange!.start, _customRange!.end).toList(growable: false);
    }
    return [];
  }

  Future<void> _pickSingleDay(BuildContext context) async {
    final now = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDay ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Choisir un jour',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) {
      setState(() {
        _customDay = DateUtils.dateOnly(picked);
        _customRange = null;
      });
    }
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = _today;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _customRange ??
          DateTimeRange(start: _customDay ?? now, end: (_customDay ?? now).add(const Duration(days: 1))),
      helpText: 'Choisir une plage de jours',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) {
      setState(() {
        _customRange = DateTimeRange(
          start: DateUtils.dateOnly(picked.start),
          end: DateUtils.dateOnly(picked.end),
        );
        _customDay = null;
      });
    }
  }

  Future<void> _refreshAll(int restaurantId) async {
    if (_tab == TopTab.dishes) {
      await Future.wait([
        ref.refresh(allDishesProvider(restaurantId).future),
        ref.refresh(unavailableDishIdsProvider((restaurantId: restaurantId, date: _yyyyMmDd(_today))).future),
      ]);
    } else {
      final dates = _datesToLoad();
      await Future.wait([
        for (final d in dates) ...[
          ref.refresh(menusWithDishesProvider((restaurantId: restaurantId, date: _yyyyMmDd(d))).future),
          ref.refresh(unavailableDishIdsProvider((restaurantId: restaurantId, date: _yyyyMmDd(d))).future),
        ]
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final restaurantId = (args?['restaurantId'] as num?)?.toInt();
    if (restaurantId == null) {
      return const Scaffold(body: Center(child: Text('Restaurant inconnu')));
    }

    // ==== Onglet PLATS ====
    final allDishesAsync = ref.watch(allDishesProvider(restaurantId));
    final unavailForTodayAsync =
    ref.watch(unavailableDishIdsProvider((restaurantId: restaurantId, date: _yyyyMmDd(_today))));

    // ==== Onglet MENUS ====
    final dates = _datesToLoad();
    final menusPerDay = <DateTime, AsyncValue<List<Menu>>>{};
    final unavailPerDay = <DateTime, AsyncValue<Set<int>>>{};
    if (_tab == TopTab.menus) {
      for (final d in dates) {
        final key = (restaurantId: restaurantId, date: _yyyyMmDd(d));
        menusPerDay[d] = ref.watch(menusWithDishesProvider(key));
        unavailPerDay[d] = ref.watch(unavailableDishIdsProvider(key));
      }
    }

    // Erreurs / chargement
    Object? firstError;
    void collect(AsyncValue a) => a.when(data: (_) {}, loading: () {}, error: (e, _) => firstError ??= e);
    if (_tab == TopTab.dishes) {
      collect(allDishesAsync);
      collect(unavailForTodayAsync);
    } else {
      for (final a in menusPerDay.values) collect(a);
      for (final a in unavailPerDay.values) collect(a);
    }
    final isLoading = _tab == TopTab.dishes
        ? (allDishesAsync.isLoading || unavailForTodayAsync.isLoading)
        : (menusPerDay.values.any((a) => a.isLoading) || unavailPerDay.values.any((a) => a.isLoading));

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Menu', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshAll(restaurantId),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            // ===== Toggle haut : PLATS / MENUS =====
            Row(
              children: [
                _ScopeChip(
                  label: 'Plats',
                  selected: _tab == TopTab.dishes,
                  onTap: () => setState(() => _tab = TopTab.dishes),
                ),
                const SizedBox(width: 8),
                _ScopeChip(
                  label: 'Menus',
                  selected: _tab == TopTab.menus,
                  onTap: () => setState(() => _tab = TopTab.menus),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ===== Contenu selon l’onglet =====
            if (isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (firstError != null)
              _ErrorState(
                message: 'Erreur de chargement',
                detail: '$firstError',
                onRetry: () => _refreshAll(restaurantId),
              )
            else if (_tab == TopTab.dishes) ...[
                // ===== Onglet PLATS =====
                // Recherche
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un plat…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  ),
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 250), () {
                      setState(() => _query = v.trim().toLowerCase());
                    });
                  },
                ),
                const SizedBox(height: 12),

                const Text('Tous les plats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final dishes = allDishesAsync.asData?.value ?? const <Dish>[];
                  final unavailIds = unavailForTodayAsync.asData?.value ?? <int>{};
                  final list = _query.isEmpty
                      ? dishes
                      : dishes
                      .where((d) =>
                  d.name.toLowerCase().contains(_query) ||
                      d.description.toLowerCase().contains(_query))
                      .toList();

                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _query.isEmpty ? 'Aucun plat.' : 'Aucun résultat pour “$_query”.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final dish in list)
                        Padding(
                          key: ValueKey('all_${dish.id}'),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: LargeDishRowCard(
                            dish: dish,
                            unavailable: unavailIds.contains(dish.id),
                            onTap: () => Navigator.pushNamed(
                              context,
                              DishDetailScreen.route,
                              arguments: {
                                'dish': dish,
                                'restaurantId': restaurantId,
                                'date': _yyyyMmDd(_today),
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ] else ...[
                // ===== Onglet MENUS =====
                // Sélecteur de portée (ne s’affiche que dans l’onglet Menus)
                Row(
                  children: [
                    _ScopeChip(
                      label: 'Aujourd’hui',
                      selected: _scope == MenuScope.today,
                      onTap: () => setState(() {
                        _scope = MenuScope.today;
                        _customDay = null;
                        _customRange = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _ScopeChip(
                      label: 'Choisir un jour/plage',
                      selected: _scope == MenuScope.custom,
                      onTap: () => setState(() => _scope = MenuScope.custom),
                    ),
                  ],
                ),
                if (_scope == MenuScope.custom) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.event),
                        label: Text(_customDay == null
                            ? 'Choisir un jour'
                            : 'Jour : ${_customDay!.day.toString().padLeft(2,'0')}/${_customDay!.month.toString().padLeft(2,'0')}'),
                        onPressed: () => _pickSingleDay(context),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_customRange == null
                            ? 'Choisir une plage'
                            : 'Plage : ${_customRange!.start.day.toString().padLeft(2,'0')}/${_customRange!.start.month.toString().padLeft(2,'0')} → ${_customRange!.end.day.toString().padLeft(2,'0')}/${_customRange!.end.month.toString().padLeft(2,'0')}'),
                        onPressed: () => _pickRange(context),
                      ),
                      if (_customDay != null || _customRange != null)
                        TextButton(
                          onPressed: () => setState(() {
                            _customDay = null;
                            _customRange = null;
                          }),
                          child: const Text('Réinitialiser'),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                if (dates.isEmpty)
                  _EmptyState(message: 'Sélectionne un jour ou une plage pour afficher les menus.')
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final d in dates) ...[
                        _DaySectionHeader(date: d),
                        const SizedBox(height: 8),
                        Builder(builder: (context) {
                          final menus = menusPerDay[d]!.asData?.value ?? const <Menu>[];
                          final unavail = unavailPerDay[d]!.asData?.value ?? <int>{};

                          if (menus.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text('Aucun menu pour cette date.', style: TextStyle(color: Colors.grey.shade700)),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final m in menus) ...[
                                Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                                if ((m.description ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                                    child: Text(m.description!, style: const TextStyle(color: Colors.black87)),
                                  ),
                                // Items du menu
                                ...m.items.map((it) {
                                  final dsh = it.dish;
                                  if (dsh == null) return const SizedBox.shrink();
                                  return Padding(
                                    key: ValueKey('menu_${m.id}_dish_${dsh.id}'),
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: LargeDishRowCard(
                                      dish: dsh,
                                      unavailable: unavail.contains(dsh.id),
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        DishDetailScreen.route,
                                        arguments: {
                                          'dish': dsh,
                                          'restaurantId': restaurantId,
                                          'date': _yyyyMmDd(d),
                                        },
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

// UI helpers (inchangés)
class _ScopeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ScopeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? kPrimaryGreen : const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySectionHeader extends StatelessWidget {
  final DateTime date;
  const _DaySectionHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateUtils.dateOnly(DateTime.now());
    final diff = date.difference(now).inDays;
    String label;
    if (diff == 0) {
      label = 'Aujourd’hui';
    } else if (diff == 1) {
      label = 'Demain';
    } else {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      final wd = days[date.weekday - 1];
      final dd = date.day.toString().padLeft(2, '0');
      final mm = date.month.toString().padLeft(2, '0');
      label = '$wd $dd/$mm';
    }
    return Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(message, style: TextStyle(color: Colors.grey.shade700)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  const _ErrorState({required this.message, this.detail, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(detail!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }
}
