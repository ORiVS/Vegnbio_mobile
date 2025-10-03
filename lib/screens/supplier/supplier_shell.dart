// lib/screens/supplier/supplier_shell.dart
import 'package:flutter/material.dart';
import 'catalog/supplier_catalog_screen.dart';
import 'reviews/supplier_reviews_screen.dart';
import 'profile/supplier_profile_screen.dart';
import 'inbox/supplier_inbox_screen.dart';

class SupplierShell extends StatefulWidget {
  static const route = '/supplier';
  const SupplierShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<SupplierShell> createState() => _SupplierShellState();
}

class _SupplierShellState extends State<SupplierShell> {
  late int _index;
  final _bucket = PageStorageBucket();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
    _pages = const [
      SupplierCatalogScreen(key: PageStorageKey('supplier_catalog')),
      SupplierInboxScreen(key: PageStorageKey('supplier_inbox')),
      SupplierReviewsScreen(key: PageStorageKey('supplier_reviews')),
      SupplierProfileScreen(key: PageStorageKey('supplier_profile')),
    ];
  }

  Future<bool> _onWillPop() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: PageStorage(
            bucket: _bucket,
            child: IndexedStack(index: _index, children: _pages),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Mes offres',
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox),
              label: 'Boîte',
            ),
            NavigationDestination(
              icon: Icon(Icons.reviews_outlined),
              selectedIcon: Icon(Icons.reviews),
              label: 'Avis',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
