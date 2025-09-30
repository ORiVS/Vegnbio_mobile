// lib/screens/home/role_home_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../client/client_shell.dart';
import '../resto/resto_shell.dart';
import '../supplier/supplier_shell.dart';

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
        return const SupplierShell();
      default:
        return const ClientShell();
    }
  }
}
