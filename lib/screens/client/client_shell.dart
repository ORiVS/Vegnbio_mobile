import 'package:flutter/material.dart';
import 'restaurants_list_screen.dart';
import 'reservations_list_screen.dart';

class ClientShell extends StatefulWidget {
  static const route = '/c/shell';
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _i = 0;
  final _pages = const [
    ClientRestaurantsScreen(),
    ClientReservationsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_rounded), label: 'Restaurants'),
          NavigationDestination(icon: Icon(Icons.assignment_rounded), label: 'Réservations'),
        ],
      ),
    );
  }
}
