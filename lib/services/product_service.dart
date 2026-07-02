import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

final List<Product> favoriteProducts = [];

Future<void> saveProducts() async {
  final prefs = await SharedPreferences.getInstance();

  final data = favoriteProducts.map((p) => jsonEncode(p.toJson())).toList();

  await prefs.setStringList('products', data);
}

Future<void> loadProducts() async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getStringList('products');

  if (data == null) return;

  favoriteProducts.clear();

  for (final item in data) {
    try {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      favoriteProducts.add(Product.fromJson(decoded));
    } catch (e) {
      print('FEHLER: $e');
      print(item);
    }
  }
}
