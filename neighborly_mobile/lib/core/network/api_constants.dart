import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration constants matching the FastAPI backend.
class ApiConstants {
  ApiConstants._();

  // For web (Chrome): use localhost directly.
  // For Android emulator: 10.0.2.2 maps to host's localhost.
  // For physical device: use your machine's LAN IP.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    return 'http://10.0.2.2:8000/api/v1';
  }

  // ─── Auth ─────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // ─── Items ────────────────────────────────────────────────
  static const String items = '/items';
  static String item(String id) => '/items/$id';
  static const String itemSearch = '/items/search';
  static String itemAvailability(String id) => '/items/$id/availability';

  // ─── Rental Requests ──────────────────────────────────────
  static const String rentalRequests = '/rental-requests';
  static const String incomingRequests = '/rental-requests/incoming';
  static String acceptRequest(String id) => '/rental-requests/$id/accept';
  static String rejectRequest(String id) => '/rental-requests/$id/reject';
  static String counterRequest(String id) => '/rental-requests/$id/counter';
  static String cancelRequest(String id) => '/rental-requests/$id/cancel';

  // ─── Transactions ─────────────────────────────────────────
  static const String transactions = '/transactions';
  static const String confirmTransaction = '/transactions/confirm';
  static String transaction(String id) => '/transactions/$id';
  static String transactionStatus(String id) => '/transactions/$id/status';

  // ─── Payments ─────────────────────────────────────────────
  static const String payments = '/payments';
  static String transactionPayments(String id) => '/payments/transaction/$id';
  static String collectPayment(String id) => '/payments/$id/collect';
  static String releasePayment(String id) => '/payments/$id/release';

  // ─── Reviews ──────────────────────────────────────────────
  static const String reviews = '/reviews';
  static String userReviews(String userId) => '/reviews/user/$userId';

  // ─── Disputes ─────────────────────────────────────────────
  static const String disputes = '/disputes';
  static String disputeReview(String id) => '/disputes/$id/review';
  static String disputeResolve(String id) => '/disputes/$id/resolve';

  // ─── Health ───────────────────────────────────────────────
  static const String health = '/health';
}
