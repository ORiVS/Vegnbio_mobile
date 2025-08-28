import 'package:flutter/material.dart';

class SupplierHomeScreen extends StatelessWidget {
  const SupplierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fournisseur'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: const Center(
        child: Text('Home Fournisseur — publier offres, suivre marketplace.'),
      ),
    );
  }
}
