// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';

// Auth
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Router par rôle + shells
import 'screens/home/role_home_router.dart';

// Client
import 'screens/client/client_shell.dart';
import 'screens/client/restaurants_list_screen.dart';
import 'screens/client/restaurant_detail_screen.dart';
import 'screens/client/reservation_new_screen.dart';
import 'screens/client/reservations_list_screen.dart';
import 'screens/client/dish_detail_screen.dart';
import 'screens/client/event_detail_screen.dart';
import 'screens/client/restaurant_menu_screen.dart';

// Client – Panier & Commandes
import 'screens/cart/cart_screen.dart';
import 'screens/cart/checkout_screen.dart';
import 'screens/cart/order_confirmation_screen.dart';

// Restaurateur
import 'screens/resto/resto_shell.dart';
import 'screens/resto/resto_dashboard_screen.dart';
import 'screens/resto/resto_reservations_screen.dart';

// Client – Profil
import 'screens/client/profile/profile_screen.dart';
import 'screens/client/profile/profile_loyalty_screen.dart';
import 'screens/client/profile/profile_edit_screen.dart';
import 'screens/client/profile/profile_order_history_screen.dart';
import 'screens/client/profile/profile_settings_screen.dart';

// Fournisseur
import 'screens/supplier/supplier_shell.dart';
import 'screens/supplier/catalog/supplier_catalog_screen.dart';
import 'screens/supplier/catalog/supplier_offer_form_screen.dart';
import 'screens/supplier/catalog/supplier_offer_detail_screen.dart';
import 'screens/supplier/reviews/supplier_reviews_screen.dart';
import 'screens/supplier/reviews/supplier_review_detail_screen.dart';
import 'screens/supplier/profile/supplier_profile_screen.dart';
import 'screens/supplier/inbox/supplier_inbox_screen.dart';
import 'screens/supplier/inbox/supplier_order_detail_screen.dart';
import 'screens/supplier/inbox/supplier_order_review_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Charge ton .env (ex: .env ou .env.prod selon build)
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: VegnBioApp()));
}

class VegnBioApp extends StatelessWidget {
  const VegnBioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Veg'N Bio",
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      // L’écran racine est décidé dynamiquement selon l’auth
      home: const _AuthGate(),

      // 💡 Toutes les routes nommées utilisées avec Navigator.pushNamed
      routes: {
        // Router par rôle
        RoleHomeRouter.route: (_) => const RoleHomeRouter(),

        // ===== CLIENT =====
        ClientShell.route: (_) => const ClientShell(),
        ClientRestaurantsScreen.route: (_) => const ClientRestaurantsScreen(),
        ClientRestaurantDetailScreen.route: (_) => const ClientRestaurantDetailScreen(),
        ClientReservationNewScreen.route: (_) => const ClientReservationNewScreen(),
        ClientReservationsScreen.route: (_) => const ClientReservationsScreen(),
        ClientRestaurantMenuScreen.route: (_) => const ClientRestaurantMenuScreen(),
        DishDetailScreen.route: (_) => const DishDetailScreen(),
        EventDetailScreen.route: (_) => const EventDetailScreen(),

        // Panier / Commandes (⚠️ étaient commentées)
        CartScreen.route: (_) => const CartScreen(),
        CheckoutScreen.route: (_) => const CheckoutScreen(),
        OrderConfirmationScreen.route: (_) => const OrderConfirmationScreen(),

        // Profil client
        ClientProfileScreen.route: (_) => const ClientProfileScreen(),
        ProfileLoyaltyScreen.route: (_) => const ProfileLoyaltyScreen(),
        ProfileEditScreen.route: (_) => const ProfileEditScreen(),
        ProfileOrderHistoryScreen.route: (_) => const ProfileOrderHistoryScreen(),
        ProfileSettingsScreen.route: (_) => const ProfileSettingsScreen(),

        // ===== RESTAURATEUR =====
        RestoShell.route: (_) => const RestoShell(),
        RestoDashboardScreen.route: (_) => const RestoDashboardScreen(),
        RestoReservationsScreen.route: (_) => const RestoReservationsScreen(),

        // ===== FOURNISSEUR =====
        SupplierShell.route: (_) => const SupplierShell(),
        SupplierCatalogScreen.route: (_) => const SupplierCatalogScreen(),
        SupplierOfferFormScreen.route: (_) => const SupplierOfferFormScreen(),
        SupplierOfferDetailScreen.route: (_) => const SupplierOfferDetailScreen(),
        SupplierInboxScreen.route: (_) => const SupplierInboxScreen(),
        SupplierOrderDetailScreen.route: (_) => const SupplierOrderDetailScreen(),
        SupplierOrderReviewScreen.route: (_) => const SupplierOrderReviewScreen(),

        // Navigation directe (si utilisée)
        '/supplier/reviews': (_) => const SupplierReviewsScreen(),
        SupplierReviewDetailScreen.route: (_) => const SupplierReviewDetailScreen(),
        '/supplier/profile': (_) => const SupplierProfileScreen(),

        // ===== AUTH =====
        LoginScreen.route: (_) => const LoginScreen(),
        RegisterScreen.route: (_) => const RegisterScreen(),
      },
    );
  }
}

/// Décide de l’écran d’entrée selon l’état d’auth
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Splash de chargement pendant la restauration de session
    if (auth.loading && auth.user == null && !auth.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Utilisateur connecté -> routeur par rôle
    if (auth.isAuthenticated && auth.user != null) {
      return const RoleHomeRouter();
    }

    // Non connecté -> écran de login
    return const LoginScreen();
  }
}
