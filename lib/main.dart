import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme.dart';
import 'core/nav.dart';
import 'core/require_auth.dart';
import 'providers/auth_provider.dart';

// Auth
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Client
import 'screens/client/client_shell.dart';
import 'screens/client/restaurants_list_screen.dart';
import 'screens/client/restaurant_detail_screen.dart';
import 'screens/client/reservation_new_screen.dart';
import 'screens/client/reservations_list_screen.dart';
import 'screens/client/dish_detail_screen.dart';
import 'screens/client/event_detail_screen.dart';
import 'screens/client/restaurant_menu_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/cart/checkout_screen.dart';
import 'screens/cart/order_confirmation_screen.dart';
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

// Vegbot
import 'screens/vetbot/vegbot_chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: VegnBioApp()));
}

class VegnBioApp extends ConsumerWidget {
  const VegnBioApp({super.key});

  /// Route builder central avec gardes
  Route<dynamic> _buildRoute(RouteSettings s, WidgetRef ref) {
    final name = s.name ?? '';

    Widget page;
    bool requireAuth = false;
    Set<String>? allowedRoles;
    Set<String>? roleOnly;

    switch (name) {
    // Auth
      case LoginScreen.route:
        page = const LoginScreen();
        break;
      case RegisterScreen.route:
        page = const RegisterScreen();
        break;

    // ===== CLIENT (Shell + pages) =====
      case ClientShell.route:
      case ClientRestaurantsScreen.route:
        page = const ClientShell();
        roleOnly = {'CLIENT'};
        break;
      case ClientRestaurantDetailScreen.route:
        page = const ClientRestaurantDetailScreen();
        roleOnly = {'CLIENT'};
        break;
      case ClientReservationNewScreen.route:
        page = const ClientReservationNewScreen();
        requireAuth = true; allowedRoles = {'CLIENT'};
        break;
      case ClientReservationsScreen.route:
        page = const ClientReservationsScreen();
        requireAuth = true; allowedRoles = {'CLIENT'};
        break;
      case ClientRestaurantMenuScreen.route:
        page = const ClientRestaurantMenuScreen();
        roleOnly = {'CLIENT'};
        break;
      case DishDetailScreen.route:
        page = const DishDetailScreen();
        roleOnly = {'CLIENT'};
        break;
      case EventDetailScreen.route:
        page = const EventDetailScreen();
        roleOnly = {'CLIENT'};
        break;

    // Panier / commandes
      case CartScreen.route:
        page = const CartScreen();
        requireAuth = true; allowedRoles = {'CLIENT'};
        break;
      case CheckoutScreen.route:
        page = const CheckoutScreen();
        requireAuth = true; allowedRoles = {'CLIENT'};
        break;
      case OrderConfirmationScreen.route:
        page = const OrderConfirmationScreen();
        requireAuth = true; allowedRoles = {'CLIENT'};
        break;

    // Profil client
      case ClientProfileScreen.route:
        page = const ClientProfileScreen();
        requireAuth = true; allowedRoles = {'CLIENT'};
        break;
      case ProfileLoyaltyScreen.route:
        page = const ProfileLoyaltyScreen();
        requireAuth = true; allowedRoles = {'CLIENT'};
        break;
      case ProfileEditScreen.route:
        page = const ProfileEditScreen();
        requireAuth = true; allowedRoles = {'CLIENT'};
        break;
      case ProfileOrderHistoryScreen.route:
        page = const ProfileOrderHistoryScreen();
        requireAuth = true; allowedRoles = {'CLIENT'};
        break;
      case ProfileSettingsScreen.route:
        page = const ProfileSettingsScreen();
        requireAuth = true; allowedRoles = {'CLIENT'};
        break;

    // ===== FOURNISSEUR (Shell + pages) =====
      case SupplierShell.route:
        page = const SupplierShell();
        requireAuth = true; allowedRoles = {'FOURNISSEUR'};
        break;
      case SupplierCatalogScreen.route:
        page = const SupplierCatalogScreen();
        requireAuth = true; allowedRoles = {'FOURNISSEUR'};
        break;
      case SupplierOfferFormScreen.route:
        page = const SupplierOfferFormScreen();
        requireAuth = true; allowedRoles = {'FOURNISSEUR'};
        break;
      case SupplierOfferDetailScreen.route:
        page = const SupplierOfferDetailScreen();
        requireAuth = true; allowedRoles = {'FOURNISSEUR'};
        break;
      case SupplierInboxScreen.route:
        page = const SupplierInboxScreen();
        requireAuth = true; allowedRoles = {'FOURNISSEUR'};
        break;
      case SupplierOrderDetailScreen.route:
        page = const SupplierOrderDetailScreen();
        requireAuth = true; allowedRoles = {'FOURNISSEUR'};
        break;
      case SupplierOrderReviewScreen.route:
        page = const SupplierOrderReviewScreen();
        requireAuth = true; allowedRoles = {'FOURNISSEUR'};
        break;
      case '/supplier/reviews':
        page = const SupplierReviewsScreen();
        requireAuth = true; allowedRoles = {'FOURNISSEUR'};
        break;
      case SupplierReviewDetailScreen.route:
        page = const SupplierReviewDetailScreen();
        requireAuth = true; allowedRoles = {'FOURNISSEUR'};
        break;
      case '/supplier/profile':
        page = const SupplierProfileScreen();
        requireAuth = true; allowedRoles = {'FOURNISSEUR'};
        break;

    // Vegbot
      case VegbotChatScreen.route:
        page = const VegbotChatScreen();
        break;

    // Fallback → espace client (public)
      default:
        page = const ClientShell();
        roleOnly = {'CLIENT'};
        break;
    }

    if (requireAuth) {
      return MaterialPageRoute(
        builder: (_) => RequireAuthPage(builder: (_) => page, allowedRoles: allowedRoles),
        settings: s,
      );
    }
    if (roleOnly != null) {
      return MaterialPageRoute(
        builder: (_) => RoleOnlyPage(builder: (_) => page, allowedRoles: roleOnly!),
        settings: s,
      );
    }
    return MaterialPageRoute(builder: (_) => page, settings: s);
  }

  /// Écran de départ **rôle-aware** :
  /// - Non connecté → ClientShell (liste des restos)
  /// - Connecté CLIENT → ClientShell
  /// - Connecté FOURNISSEUR → SupplierShell
  Widget _startupHome(WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.loading && auth.user == null && !auth.isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.isAuthenticated && auth.user != null) {
      return auth.user!.role == 'FOURNISSEUR'
          ? const SupplierShell()
          : const ClientShell();
    }
    return const ClientShell();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,        // ← important pour showAuthDialog & interceptors
      title: "Veg'N Bio",
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: _startupHome(ref),
      onGenerateRoute: (s) => _buildRoute(s, ref),
    );
  }
}
