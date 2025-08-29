// lib/screens/client/client_restaurants_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/restaurant.dart';
import '../../providers/restaurants_provider.dart';
import '../../theme/app_colors.dart';
import 'restaurant_detail_screen.dart';

class ClientRestaurantsScreen extends ConsumerWidget {
  static const route = '/c/restaurants';
  const ClientRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(restaurantsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "RESTAURANTS",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kPrimaryGreenDark,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const _SearchField(),
            const SizedBox(height: 16),

            Expanded(
              child: async.when(
                data: (list) {
                  final state = _SearchState.of(context);
                  final q = state?.query.toLowerCase() ?? '';
                  final filtered = q.isEmpty
                      ? list
                      : list
                      .where((r) =>
                  r.name.toLowerCase().contains(q) ||
                      r.city.toLowerCase().contains(q) ||
                      r.address.toLowerCase().contains(q))
                      .toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Aucun restaurant trouvé.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (c, i) {
                      final r = filtered[i];
                      return InkWell(
                        onTap: () => Navigator.pushNamed(
                          c,
                          ClientRestaurantDetailScreen.route,
                          arguments: r.id,
                        ),
                        child: _RestaurantCard(r: r),
                      );
                    },
                  );
                },
                loading: () =>
                const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SearchState(
      query: _ctrl.text,
      child: TextField(
        controller: _ctrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Rechercher un restaurant…',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          isDense: true, // réduit la hauteur
          fillColor: const Color(0xFFF7F7F8),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }
}

class _SearchState extends InheritedWidget {
  final String query;
  const _SearchState({required this.query, required super.child, super.key});

  static _SearchState? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SearchState>();

  @override
  bool updateShouldNotify(covariant _SearchState oldWidget) =>
      query != oldWidget.query;
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant r;
  const _RestaurantCard({required this.r});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                color: const Color(0xFFEFF6F3),
                alignment: Alignment.center,
                child: Text(
                  (r.name.isNotEmpty ? r.name[0] : '?').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kPrimaryGreenDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    r.address.isNotEmpty ? r.address : r.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: [
                      if (r.wifi) const _Chip('Wifi'),
                      if (r.printer) const _Chip('Imprimante'),
                      if (r.animationsEnabled)
                        _Chip('Animations${r.animationDay != null ? " (${r.animationDay})" : ""}'),
                      if (r.memberTrays) const _Chip('Plateaux membres'),
                      if (r.deliveryTrays) const _Chip('Plateaux livrables'),
                      if (r.capacity > 0) _Chip('${r.capacity} places'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      backgroundColor: kChipBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
    );
  }
}
