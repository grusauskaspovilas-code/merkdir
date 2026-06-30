import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, List<String>>> checkNearbyStores({
  required double notificationDistance,
}) async {

  final result = <String, List<String>>{};

  final position = await Geolocator.getCurrentPosition();

  final lat = position.latitude;
  final lon = position.longitude;

  final prefs = await SharedPreferences.getInstance();
  final shoppingData = prefs.getStringList('shoppingList') ?? [];

  final query = """
[out:json];
(
  node["shop"~"supermarket|convenience"](around:$notificationDistance,$lat,$lon);
  way["shop"~"supermarket|convenience"](around:$notificationDistance,$lat,$lon);
  relation["shop"~"supermarket|convenience"](around:$notificationDistance,$lat,$lon);
);
out center tags;
""";

  final response = await http.post(
    Uri.parse('https://overpass-api.de/api/interpreter'),
    headers: {
      'Content-Type': 'text/plain',
      'Accept': 'application/json',
      'User-Agent': 'MerkDir-App',
    },
    body: query,
  );

  if (response.statusCode != 200) {
    return result;
  }

  final json = jsonDecode(response.body);

  final elements = json['elements'] as List;

  for (final element in elements) {

    final tags = element['tags'] ?? {};

    final storeName = (tags['name'] ?? '').toString();

    if (storeName.isEmpty) continue;

    String normalizedStore = storeName.toLowerCase();

    if (normalizedStore.contains('voi')) normalizedStore = 'migros';
    if (normalizedStore.contains('migrolino')) normalizedStore = 'migros';
    if (normalizedStore.contains('coop pronto')) normalizedStore = 'coop';
    if (normalizedStore.contains('aldi suisse')) normalizedStore = 'aldi';

    final matches = <String>[];

    for (final itemJson in shoppingData) {

      final decoded = jsonDecode(itemJson);

      if (decoded['bought'] == true) continue;

      final stores = List<String>.from(decoded['stores'] ?? []);

      final found = stores.any(
        (s) => normalizedStore.contains(s.toLowerCase()),
      );

      if (found) {
        matches.add(decoded['name']);
      }
    }

    if (matches.isNotEmpty) {
      result[storeName] = matches;
    }
  }

  return result;
}