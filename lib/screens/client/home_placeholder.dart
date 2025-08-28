import 'package:flutter/material.dart';

class HomePlaceholder extends StatelessWidget {
  static const route = '/home';
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Veg'N Bio")),
      body: const Center(child: Text('Bienvenue – Home (placeholder)')),
    );
  }
}
