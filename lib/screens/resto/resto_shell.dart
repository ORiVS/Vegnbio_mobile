import 'package:flutter/material.dart';
import 'resto_dashboard_screen.dart';
import 'resto_reservations_screen.dart';

class RestoShell extends StatefulWidget {
  static const route = '/r/shell';
  const RestoShell({super.key});

  @override
  State<RestoShell> createState() => _RestoShellState();
}

class _RestoShellState extends State<RestoShell> {
  int _i = 0;
  final _pages = const [
    RestoDashboardScreen(),
    RestoReservationsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_customize_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.event_note), label: 'Réservations'),
        ],
      ),
    );
  }
}
