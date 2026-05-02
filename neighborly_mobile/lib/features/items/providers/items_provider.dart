import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neighborly/core/network/dio_client.dart';
import 'package:neighborly/core/network/api_constants.dart';
import 'package:neighborly/features/items/models/item.dart';

/// Items list provider (auto-refreshable).
final itemsProvider = FutureProvider.autoDispose<List<Item>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.items, queryParameters: {'limit': 50});
  return (response.data as List).map((json) => Item.fromJson(json)).toList();
});

/// Single item detail provider.
final itemDetailProvider =
    FutureProvider.autoDispose.family<Item, String>((ref, itemId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.item(itemId));
  return Item.fromJson(response.data);
});

/// Item search provider.
final itemSearchProvider = FutureProvider.autoDispose
    .family<List<Item>, Map<String, dynamic>>((ref, params) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.itemSearch, queryParameters: params);
  final data = response.data;
  // Backend returns {data: [...], next_cursor: ..., has_more: ...}
  final items = (data['data'] as List).map((json) => Item.fromJson(json)).toList();
  return items;
});

/// Create item action.
Future<Item> createItem(Dio dio, {
  required String title,
  required String category,
  required double dailyRate,
  String? description,
  double? weeklyRate,
  double depositRequired = 0,
  String? conditionDescription,
  List<String>? imageUrls,
}) async {
  final response = await dio.post(ApiConstants.items, data: {
    'title': title,
    'category': category,
    'daily_rate': dailyRate,
    if (description != null) 'description': description,
    if (weeklyRate != null) 'weekly_rate': weeklyRate,
    'deposit_required': depositRequired,
    if (conditionDescription != null) 'condition_description': conditionDescription,
    if (imageUrls != null) 'image_urls': imageUrls,
  });
  return Item.fromJson(response.data);
}

/// Update item action.
Future<Item> updateItem(Dio dio, String itemId, Map<String, dynamic> updates) async {
  final response = await dio.put(ApiConstants.item(itemId), data: updates);
  return Item.fromJson(response.data);
}

/// Delete item action.
Future<void> deleteItem(Dio dio, String itemId) async {
  await dio.delete(ApiConstants.item(itemId));
}
