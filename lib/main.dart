import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vegnbio_app/screens/client/dish_detail_screen.dart';
import 'package:vegnbio_app/screens/client/event_detail_screen.dart';
import 'package:vegnbio_app/screens/client/restaurant_menu_screen.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';

// Auth
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Router par rôle + shells
import 'screens/home/role_home_router.dart';
import 'screens/client/client_shell.dart';
import 'screens/client/restaurants_list_screen.dart';
import 'screens/client/restaurant_detail_screen.dart';
import 'screens/client/reservation_new_screen.dart';
import 'screens/client/reservations_list_screen.dart';
import 'screens/resto/resto_shell.dart';
import 'screens/resto/resto_dashboard_screen.dart';
import 'screens/resto/resto_reservations_screen.dart';

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
      // ✅ AuthGate décide dynamiquement (Login vs Home) selon l'état provider.
      home: const _AuthGate(),

      // Routes nommées
      routes: {
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
        DishDetailScreen.route: (_) => const DishDetailScreen(),



        // Restaurateur
        RestoShell.route: (_) => const RestoShell(),
        RestoDashboardScreen.route: (_) => const RestoDashboardScreen(),
        RestoReservationsScreen.route: (_) => const RestoReservationsScreen(),


        // Auth
        LoginScreen.route: (_) => const LoginScreen(),
        RegisterScreen.route: (_) => const RegisterScreen(),
      },
    );
  }
}

/// Décide de l’écran d’entrée selon l’état d’auth (évite le piège `initialRoute`)
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Pendant le boot, on peut afficher un splash simple
    // (ex: le temps de fetch /me si un token existe)
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
