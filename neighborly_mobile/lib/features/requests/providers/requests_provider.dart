import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neighborly/core/network/dio_client.dart';
import 'package:neighborly/core/network/api_constants.dart';
import 'package:neighborly/features/requests/models/rental_request.dart';

/// My outgoing requests (as borrower).
final myRequestsProvider =
    FutureProvider.autoDispose<List<RentalRequest>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.rentalRequests);
  return (response.data as List)
      .map((json) => RentalRequest.fromJson(json))
      .toList();
});

/// Incoming requests (on items I own).
final incomingRequestsProvider =
    FutureProvider.autoDispose<List<RentalRequest>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.incomingRequests);
  return (response.data as List)
      .map((json) => RentalRequest.fromJson(json))
      .toList();
});

// ─── Request Actions ──────────────────────────────────────────

Future<RentalRequest> createRentalRequest(Dio dio, {
  required String itemId,
  required String startDate,
  required String endDate,
  required double proposedDailyRate,
  String? message,
}) async {
  final response = await dio.post(ApiConstants.rentalRequests, data: {
    'item_id': itemId,
    'start_date': startDate,
    'end_date': endDate,
    'proposed_daily_rate': proposedDailyRate,
    if (message != null) 'message': message,
  });
  return RentalRequest.fromJson(response.data);
}

Future<RentalRequest> acceptRequest(Dio dio, String requestId) async {
  final response = await dio.patch(ApiConstants.acceptRequest(requestId));
  return RentalRequest.fromJson(response.data);
}

Future<RentalRequest> rejectRequest(Dio dio, String requestId) async {
  final response = await dio.patch(ApiConstants.rejectRequest(requestId));
  return RentalRequest.fromJson(response.data);
}

Future<RentalRequest> cancelRequest(Dio dio, String requestId) async {
  final response = await dio.patch(ApiConstants.cancelRequest(requestId));
  return RentalRequest.fromJson(response.data);
}

Future<RentalRequest> counterPropose(Dio dio, String requestId, {
  required String counterStartDate,
  required String counterEndDate,
  required double counterDailyRate,
  String? counterMessage,
}) async {
  final response = await dio.patch(ApiConstants.counterRequest(requestId), data: {
    'counter_start_date': counterStartDate,
    'counter_end_date': counterEndDate,
    'counter_daily_rate': counterDailyRate,
    if (counterMessage != null) 'counter_message': counterMessage,
  });
  return RentalRequest.fromJson(response.data);
}
