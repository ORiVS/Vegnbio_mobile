import 'package:flutter/material.dart';
import 'catalog/supplier_catalog_screen.dart';
import 'reviews/supplier_reviews_screen.dart';
import 'profile/supplier_profile_screen.dart';

class SupplierShell extends StatefulWidget {
  static const route = '/supplier';
  const SupplierShell({super.key});

  @override
  State<SupplierShell> createState() => _SupplierShellState();
}

class _SupplierShellState extends State<SupplierShell> {
  int _index = 0;
  final _pages = const [
    SupplierCatalogScreen(),
    SupplierReviewsScreen(),
    SupplierProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: _pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Catalogue'),
          NavigationDestination(icon: Icon(Icons.reviews_outlined), selectedIcon: Icon(Icons.reviews), label: 'Avis'),
          NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: 'Profil'),
        ],
      ),
    );
  }
}
