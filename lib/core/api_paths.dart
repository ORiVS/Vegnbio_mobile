// lib/core/api_paths.dart
class ApiPaths {

  // ---- Accounts / Auth ----
  static const login        = '/api/accounts/login/';
  static const register     = '/api/accounts/register/';
  static const me           = '/api/accounts/me/';
  static const tokenRefresh = '/api/accounts/token/refresh/';
  static const meUpdate     = '/api/accounts/me/update/';

  // ---- Restaurants (DefaultRouter) ----
  static const restaurantsList = '/api/restaurants/restaurants/';
  static String restaurantDetail(int id) => '/api/restaurants/restaurants/$id/';

  // ---- Reservations (DefaultRouter) ----
  static const reservationsList = '/api/restaurants/reservations/';
  static String reservationDetail(int id)  => '/api/restaurants/reservations/$id/';
  static String reservationCancel(int id)  => '/api/restaurants/reservations/$id/cancel/';
  static String reservationModerate(int id)=> '/api/restaurants/reservations/$id/moderate/';
  static const reservations = '/api/restaurants/reservations/';

  // ---- Endpoints spécifiques Restaurateur ----
  static String restaurantOwnerReservations(int restaurantId)
  => '/api/restaurants/$restaurantId/reservations/';
  static String restaurantDashboard(int restaurantId)
  => '/api/restaurants/$restaurantId/dashboard/';
  static String restaurantEvenements(int id)
  => '/api/restaurants/restaurants/$id/evenements/';

  // Évènements
  static const events = '/api/restaurants/evenements/';
  static String eventDetail(int id) => '/api/restaurants/evenements/$id/';
  static String eventRegister(int id) => '/api/restaurants/evenements/$id/register/';
  static String eventUnregister(int id) => '/api/restaurants/evenements/$id/unregister/';
  static String eventRegistrations(int id) => '/api/restaurants/evenements/$id/registrations/';

  // ====== Client orders ======
  static const cart        = '/api/orders/cart/';
  static const checkout    = '/api/orders/checkout/';
  static const ordersList  = '/api/orders/';
  static const orderStatus = '/api/orders/{id}/status/';
  static const slots       = '/api/orders/slots/';

  // ====== Market (fournisseurs) ======
  static const supplierOffers   = '/api/market/offers/';
  static const supplierReviews  = '/api/market/reviews/';
  static const supplierReports  = '/api/market/reports/';
  static const supplierComments = '/api/market/comments/';

  static String supplierOfferPublish(int id) => '$supplierOffers$id/publish/';
  static String supplierOfferUnlist(int id) => '$supplierOffers$id/unlist/';
  static String supplierOfferDraft(int id)  => '$supplierOffers$id/draft/';
  static String supplierOfferFlag(int id)   => '$supplierOffers$id/flag/';
  static String supplierOffer(int id)       => '$supplierOffers$id/';

  static String supplierOffersCompare(List<int> ids) =>
      '$supplierOffers' 'compare/?ids=${ids.join(",")}';

  // ====== Purchasing (mobile fournisseur) ======
  static const purchasingOrders = '/api/purchasing/orders/';
  static const supplierInbox = '/api/purchasing/orders/supplier_inbox/'; // GET
  static String purchasingOrderDetail(int id) => '/api/purchasing/orders/$id/'; // GET
  static String purchasingOrderSupplierReview(int id)
  => '/api/purchasing/orders/$id/supplier_review/'; // POST

  // ====== Invitations d'évènements (fournisseur, in-app) ======
  static const myEventInvites = '/api/restaurants/evenements/invites/mine/';
  static String eventInviteAccept(int inviteId)
  => '/api/restaurants/evenements/invites/$inviteId/accept/';
  static String eventInviteDecline(int inviteId)
  => '/api/restaurants/evenements/invites/$inviteId/decline/';

  // ====== Fidélité ======
  static const loyaltyPoints       = '/api/fidelite/points/';
  static const loyaltyTransactions = '/api/fidelite/transactions/';
  static const loyaltyJoin         = '/api/fidelite/join/';

  // ====== Menu ======
  static const menus = '/api/menu/menus/';
  static const dishes = '/api/menu/dishes/';
  static String dish(int id) => '$dishes$id/';
  static const dishAvailabilities = '/api/menu/dish-availability/';
  static const allergens = '/api/menu/allergens/';


  static String dishAvailabilityQuery({
    required int restaurantId,
    required int dishId,
    required String date, // YYYY-MM-DD
  }) =>
      '$dishAvailabilities?restaurant=$restaurantId&dish=$dishId&date=$date';
}
