class ApiPaths {
  // ---- Accounts / Auth ----
  static const login        = '/api/accounts/login/';
  static const register     = '/api/accounts/register/';
  static const me           = '/api/accounts/me/';
  static const tokenRefresh = '/api/accounts/token/refresh/';

  static const meUpdate = '/api/accounts/me/update/';


  // ---- Restaurants (DefaultRouter) ----
  // Racine /api/restaurants/ renvoie un index de liens.
  // La vraie liste est /api/restaurants/restaurants/
  static const restaurantsList = '/api/restaurants/restaurants/';
  static String restaurantDetail(int id) => '/api/restaurants/restaurants/$id/';

  // ---- Reservations (DefaultRouter) ----
  static const reservationsList = '/api/restaurants/reservations/';
  static String reservationDetail(int id)  => '/api/restaurants/reservations/$id/';
  static String reservationCancel(int id)  => '/api/restaurants/reservations/$id/cancel/';
  static String reservationModerate(int id)=> '/api/restaurants/reservations/$id/moderate/';
  // Reservations
  static const reservations = '/api/restaurants/reservations/';

  // ---- Endpoints spécifiques Restaurateur ----
  static String restaurantOwnerReservations(int restaurantId)
  => '/api/restaurants/$restaurantId/reservations/';

  static String restaurantDashboard(int restaurantId)
  => '/api/restaurants/$restaurantId/dashboard/';

  static String restaurantEvenements(int id) =>
      '/api/restaurants/restaurants/$id/evenements/';

  // Évènements
  static const events = '/api/restaurants/evenements/';
  static String eventDetail(int id) => '/api/restaurants/evenements/$id/';
  static String eventRegister(int id) => '/api/restaurants/evenements/$id/register/';
  static String eventUnregister(int id) => '/api/restaurants/evenements/$id/unregister/';
  static String eventRegistrations(int id) => '/api/restaurants/evenements/$id/registrations/';



  // Panier / Commandes
  static const cart        = '/api/orders/cart/';       // GET/POST/DELETE
  static const checkout    = '/api/orders/checkout/';   // POST
  static const ordersList  = '/api/orders/';            // GET
  static const orderStatus = '/api/orders/{id}/status/';// GET/PATCH
  static const slots       = '/api/orders/slots/';      // GET

  // Fidélité
  static const loyaltyPoints       = '/api/fidelite/points/';
  static const loyaltyTransactions = '/api/fidelite/transactions/';
  static const loyaltyJoin         = '/api/fidelite/join/';

  static const menus = '/api/menu/menus/';
  static const dishes = '/api/menu/dishes/';
  static String dish(int id) => '$dishes$id/';
  static const dishAvailabilities = '/api/menu/dish-availability/';

  static String dishAvailabilityQuery({
    required int restaurantId,
    required int dishId,
    required String date, // YYYY-MM-DD
  }) =>
      '$dishAvailabilities?restaurant=$restaurantId&dish=$dishId&date=$date';
}
