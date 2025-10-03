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

import 'screens/resto/resto_shell.dart';
import 'screens/resto/resto_dashboard_screen.dart';
import 'screens/resto/resto_reservations_screen.dart';

// Client profile
import 'screens/client/profile/profile_screen.dart';
import 'screens/client/profile/profile_loyalty_screen.dart';
import 'screens/client/profile/profile_edit_screen.dart';
import 'screens/client/profile/profile_order_history_screen.dart';
import 'screens/client/profile/profile_settings_screen.dart';

// Supplier
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
  // Charge .env (contient API_BASE_URL). Tu peux faire ".env.prod" selon build.
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
      home: const _AuthGate(), // AuthGate décide dynamiquement (Login vs Home)

      routes: {
        // Router rôle
        RoleHomeRouter.route: (_) => const RoleHomeRouter(),

        // Client
        ClientShell.route: (_) => const ClientShell(),
        ClientRestaurantsScreen.route: (_) => const ClientRestaurantsScreen(),
        ClientRestaurantDetailScreen.route: (_) => const ClientRestaurantDetailScreen(),
        ClientReservationNewScreen.route: (_) => const ClientReservationNewScreen(),
        ClientReservationsScreen.route: (_) => const ClientReservationsScreen(),
        EventDetailScreen.route: (_) => const EventDetailScreen(),
        DishDetailScreen.route: (_) => const DishDetailScreen(),
        ClientRestaurantMenuScreen.route: (_) => const ClientRestaurantMenuScreen(),

        ClientProfileScreen.route: (_) => const ClientProfileScreen(),
        ProfileLoyaltyScreen.route: (_) => const ProfileLoyaltyScreen(),
        ProfileEditScreen.route: (_) => const ProfileEditScreen(),
        ProfileOrderHistoryScreen.route: (_) => const ProfileOrderHistoryScreen(),
        ProfileSettingsScreen.route: (_) => const ProfileSettingsScreen(),

        // Restaurateur
        RestoShell.route: (_) => const RestoShell(),
        RestoDashboardScreen.route: (_) => const RestoDashboardScreen(),
        RestoReservationsScreen.route: (_) => const RestoReservationsScreen(),

        // Panier/commandes client
        // (laisse si utilisé côté client)
        // CartScreen.route: (_) => const CartScreen(),
        // CheckoutScreen.route: (_) => const CheckoutScreen(),
        // OrderConfirmationScreen.route: (_) => const OrderConfirmationScreen(),

        // Supplier (fournisseur)
        SupplierShell.route: (_) => const SupplierShell(),
        SupplierCatalogScreen.route: (_) => const SupplierCatalogScreen(),
        SupplierOfferFormScreen.route: (_) => const SupplierOfferFormScreen(),
        SupplierOfferDetailScreen.route: (_) => const SupplierOfferDetailScreen(),
        SupplierInboxScreen.route: (_) => const SupplierInboxScreen(),
        SupplierOrderDetailScreen.route: (_) => const SupplierOrderDetailScreen(),
        SupplierOrderReviewScreen.route: (_) => const SupplierOrderReviewScreen(),

        // Supplier - reviews & profil (navigation directe si besoin)
        '/supplier/reviews': (_) => const SupplierReviewsScreen(),
        SupplierReviewDetailScreen.route: (_) => const SupplierReviewDetailScreen(),
        '/supplier/profile': (_) => const SupplierProfileScreen(),

        // Auth
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

    if (auth.loading && auth.user == null && !auth.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isAuthenticated && auth.user != null) {
      return const RoleHomeRouter();
    }
    return const LoginScreen();
  }
}
