import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../client/client_shell.dart';
import '../resto/resto_shell.dart';
import '../client/restaurants_list_screen.dart';

class RoleHomeRouter extends ConsumerWidget {
  static const route = '/home';
  const RoleHomeRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(authProvider);
    if (!st.isAuthenticated || st.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final role = st.user!.role;
    switch (role) {
      case 'CLIENT':
        return const ClientShell();
      case 'RESTAURATEUR':
        return const RestoShell();
      case 'FOURNISSEUR':
        return const Scaffold(body: Center(child: Text('Accueil Fournisseur (à venir)')));
      case 'ADMIN':
        return const Scaffold(body: Center(child: Text('Accueil Admin (à venir)')));
      default:
        return const ClientShell();
    }
  }
}
