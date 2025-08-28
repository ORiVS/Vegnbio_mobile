import 'package:flutter/material.dart';

class RestaurateurHomeScreen extends StatelessWidget {
  const RestaurateurHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurateur'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: const Center(
        child: Text('Home Restaurateur — POS, réservations, événements.'),
      ),
    );
  }
}
