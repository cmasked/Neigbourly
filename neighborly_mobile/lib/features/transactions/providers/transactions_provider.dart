import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neighborly/core/network/dio_client.dart';
import 'package:neighborly/core/network/api_constants.dart';
import 'package:neighborly/features/transactions/models/transaction.dart';

/// My transactions.
final transactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.transactions);
  return (response.data as List)
      .map((json) => Transaction.fromJson(json))
      .toList();
});

/// Single transaction detail.
final transactionDetailProvider =
    FutureProvider.autoDispose.family<Transaction, String>((ref, txnId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.transaction(txnId));
  return Transaction.fromJson(response.data);
});

/// Payments for a transaction.
final transactionPaymentsProvider =
    FutureProvider.autoDispose.family<List<Payment>, String>((ref, txnId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.transactionPayments(txnId));
  return (response.data as List)
      .map((json) => Payment.fromJson(json))
      .toList();
});

// ─── Transaction Actions ──────────────────────────────────────

Future<Transaction> confirmTransaction(Dio dio, {
  required String rentalRequestId,
  required String idempotencyKey,
}) async {
  final response = await dio.post(ApiConstants.confirmTransaction, data: {
    'rental_request_id': rentalRequestId,
    'idempotency_key': idempotencyKey,
  });
  return Transaction.fromJson(response.data);
}

Future<Transaction> updateTransactionStatus(Dio dio, String txnId, String status) async {
  final response = await dio.patch(ApiConstants.transactionStatus(txnId), data: {
    'status': status,
  });
  return Transaction.fromJson(response.data);
}

// ─── Payment Actions ──────────────────────────────────────────

Future<Payment> createPayment(Dio dio, {
  required String transactionId,
  required String paymentType,
  required double amount,
  required String idempotencyKey,
  String? gatewayProvider,
}) async {
  final response = await dio.post(ApiConstants.payments, data: {
    'transaction_id': transactionId,
    'payment_type': paymentType,
    'amount': amount,
    'idempotency_key': idempotencyKey,
    if (gatewayProvider != null) 'gateway_provider': gatewayProvider,
  });
  return Payment.fromJson(response.data);
}

// ─── Review Actions ───────────────────────────────────────────

Future<Review> createReview(Dio dio, {
  required String transactionId,
  required String revieweeId,
  required int rating,
  String? comment,
}) async {
  final response = await dio.post(ApiConstants.reviews, data: {
    'transaction_id': transactionId,
    'reviewee_id': revieweeId,
    'rating': rating,
    if (comment != null) 'comment': comment,
  });
  return Review.fromJson(response.data);
}

final userReviewsProvider =
    FutureProvider.autoDispose.family<List<Review>, String>((ref, userId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.userReviews(userId));
  return (response.data as List)
      .map((json) => Review.fromJson(json))
      .toList();
});

// ─── Dispute Actions ──────────────────────────────────────────

Future<Dispute> fileDispute(Dio dio, {
  required String transactionId,
  required String reason,
  String? damageReportId,
  List<String>? evidenceUrls,
}) async {
  final response = await dio.post(ApiConstants.disputes, data: {
    'transaction_id': transactionId,
    'reason': reason,
    if (damageReportId != null) 'damage_report_id': damageReportId,
    if (evidenceUrls != null) 'evidence_urls': evidenceUrls,
  });
  return Dispute.fromJson(response.data);
}
