class ApiPaths {
  // ---- Accounts / Auth ----
  static const login        = '/api/accounts/login/';
  static const register     = '/api/accounts/register/';
  static const me           = '/api/accounts/me/';
  static const tokenRefresh = '/api/accounts/token/refresh/';

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
}
