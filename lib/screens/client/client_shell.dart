// lib/screens/client/client_shell.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';


import 'events_list_screen.dart';
import 'restaurants_list_screen.dart';
import 'reservations_list_screen.dart';

class EvenementsScreen extends StatelessWidget {
  const EvenementsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Événements'));
}

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Mon profil'));
}

class ClientShell extends StatefulWidget {
  static const route = '/client';


  final int? initialIndex;

  const ClientShell({super.key, this.initialIndex});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;
  bool _initFromArgs = false;

  final _pages = const <Widget>[
    ClientRestaurantsScreen(),   // 0 : Accueil
    ClientReservationsScreen(),  // 1 : Réservations
    ClientEventsScreen(),          // 2 : Événements
    ProfilScreen(),              // 3 : Profil
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initFromArgs) return;

    // 1) priorité au paramètre du constructeur
    int? tab = widget.initialIndex;

    // 2) sinon, on regarde les arguments de la route nommée
    final args = ModalRoute.of(context)?.settings.arguments;
    if (tab == null) {
      if (args is int) tab = args;
      if (args is Map && args['tab'] is int) tab = args['tab'] as int;
    }

    if (tab != null && tab >= 0 && tab < _pages.length) {
      _index = tab;
    }
    _initFromArgs = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On garde l'état des pages (scroll/resto/resas) entre les onglets
      body: SafeArea(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            backgroundColor: Colors.white,
            height: 65,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            indicatorColor: kPrimaryGreen.withOpacity(.15),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Réservations',
              ),
              NavigationDestination(
                icon: Icon(Icons.celebration_outlined),
                selectedIcon: Icon(Icons.celebration),
                label: 'Événements',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
