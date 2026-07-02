import 'dart:convert';

import 'shopping_item.dart';

class NotificationData {
  final String store;
  final List<ShoppingItem> items;

  const NotificationData({
    required this.store,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'store': store,
      'items': items
          .map(
            (item) => {
              'name': item.name,
              'stores': item.stores,
              'priority': item.priority,
              'bought': item.bought,
            },
          )
          .toList(),
    };
  }

  String toPayload() => jsonEncode(toJson());

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return NotificationData(
      store: (json['store'] ?? '').toString(),
      items: rawItems is List
          ? rawItems.map((item) {
              if (item is Map<String, dynamic>) {
                return ShoppingItem(
                  name: (item['name'] ?? '').toString(),
                  stores: List<String>.from(item['stores'] ?? []),
                  priority: (item['priority'] ?? 'Normal').toString(),
                  bought: item['bought'] == true,
                );
              }

              return ShoppingItem(
                name: item.toString(),
                stores: const [],
                priority: 'Normal',
              );
            }).toList()
          : const [],
    );
  }

  factory NotificationData.fromPayload(String payload) {
    final decoded = jsonDecode(payload);

    if (decoded is Map<String, dynamic>) {
      return NotificationData.fromJson(decoded);
    }

    return const NotificationData(store: '', items: []);
  }
}
