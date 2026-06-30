import 'dart:convert';

import '../services/store_service.dart';

List<String> findMatchingItems(
  List<String>? data,
  String storeName,
) {
  final matchingItems = <String>[];

  final normalizedStore = normalizeStore(storeName);

  for (final itemJson in data ?? []) {
    final decoded = jsonDecode(itemJson);

    final bought = decoded['bought'] ?? false;

    if (bought) continue;

    final stores =
        List<String>.from(decoded['stores'] ?? []);

    final matches = stores.any(
      (s) => normalizedStore.contains(
        s.toLowerCase(),
      ),
    );

    if (matches) {
      matchingItems.add(decoded['name']);
    }
  }

  return matchingItems;
}