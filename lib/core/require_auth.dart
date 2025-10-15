import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/nav.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/client/client_shell.dart';
import '../screens/supplier/supplier_shell.dart';

/// ───────────────────────────────────────────────────────────
/// 1) Modale globale "Connexion requise"
///    - Utilisée par ApiService (guard réseau)
///    - Retourne true si l’utilisateur clique "Se connecter"
/// ───────────────────────────────────────────────────────────
Future<bool> showAuthDialog({
  String title = 'Connexion requise',
  String message = 'Vous devez être connecté pour continuer.',
  String cancelText = 'Annuler',
  String okText = 'Se connecter',
}) async {
  final ctx = currentNavContext;
  if (ctx == null) return false;

  final accepted = await showDialog<bool>(
    context: ctx,
    barrierDismissible: true,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c, rootNavigator: true).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(c, rootNavigator: true).pop(true),
          child: Text(okText),
        ),
      ],
    ),
  );

  return accepted ?? false;
}

/// ───────────────────────────────────────────────────────────
/// 2) Garde "connexion + rôle" pour pages protégées
/// ───────────────────────────────────────────────────────────
class RequireAuthPage extends ConsumerWidget {
  final WidgetBuilder builder;
  final Set<String>? allowedRoles; // ex: {'FOURNISSEUR'}

  const RequireAuthPage({
    super.key,
    required this.builder,
    this.allowedRoles,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // pas connecté → invite login
    if (!auth.isAuthenticated || auth.user == null) {
      Future.microtask(() async {
        final accepted = await showAuthDialog();
        if (accepted) {
          appNavigatorKey.currentState?.pushNamed(LoginScreen.route);
        }
      });
      return const SizedBox.shrink();
    }

    // connecté mais rôle non autorisé → redirige vers espace adapté
    if (allowedRoles != null && !allowedRoles!.contains(auth.user!.role)) {
      Future.microtask(() async {
        final isSupplier = auth.user!.role == 'FOURNISSEUR';
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => const AlertDialog(
            title: Text('Accès non autorisé'),
            content: Text(
              "Vous allez être redirigé vers votre espace correspondant à votre rôle.",
            ),
          ),
        );
        appNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => isSupplier ? const SupplierShell() : const ClientShell()),
              (_) => false,
        );
      });
      return const SizedBox.shrink();
    }

    return builder(context);
  }
}

/// ───────────────────────────────────────────────────────────
/// 3) Garde "rôle uniquement" (autorise non-connectés)
///    -> utile pour empêcher un fournisseur connecté d’aller dans l’espace client
/// ───────────────────────────────────────────────────────────
class RoleOnlyPage extends ConsumerWidget {
  final WidgetBuilder builder;
  final Set<String> allowedRoles; // ex: {'CLIENT'}

  const RoleOnlyPage({
    super.key,
    required this.builder,
    required this.allowedRoles,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // non connecté → autorisé
    if (!auth.isAuthenticated || auth.user == null) {
      return builder(context);
    }

    // connecté mais rôle incompatible → redirection
    if (!allowedRoles.contains(auth.user!.role)) {
      Future.microtask(() async {
        final isSupplier = auth.user!.role == 'FOURNISSEUR';
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => const AlertDialog(
            title: Text('Espace indisponible'),
            content: Text("Redirection vers votre espace."),
          ),
        );
        appNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => isSupplier ? const SupplierShell() : const ClientShell()),
              (_) => false,
        );
      });
      return const SizedBox.shrink();
    }

    return builder(context);
  }
}
