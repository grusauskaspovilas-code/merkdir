import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_item.dart';

final List<ShoppingItem> shoppingList = [];

Future<void> saveShoppingList() async {
  final prefs = await SharedPreferences.getInstance();

  final data = shoppingList.map((item) {
    return jsonEncode({
      'name': item.name,
      'stores': item.stores,
      'priority': item.priority,
      'bought': item.bought,
    });
  }).toList();

  await prefs.setStringList('shoppingList', data);
}

Future<void> loadShoppingList() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); 
  final data = prefs.getStringList('shoppingList');

  if (data == null) return;

  shoppingList.clear();

  for (final item in data) {
    final decoded = jsonDecode(item);

    shoppingList.add(
      ShoppingItem(
        name: decoded['name'],
        stores: List<String>.from(decoded['stores'] ?? []),
        priority: decoded['priority'],
        bought: decoded['bought'],
      )
    );
  }
}
