import 'dart:convert';

import 'package:http/http.dart' as http;

Future<List<dynamic>> findNearbyStores(
  double lat,
  double lon,
  double radius,
) async {

  final query = """
[out:json];
(
  node["shop"~"supermarket|convenience"](around:$radius,$lat,$lon);
  way["shop"~"supermarket|convenience"](around:$radius,$lat,$lon);
  relation["shop"~"supermarket|convenience"](around:$radius,$lat,$lon);
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
).timeout(
  const Duration(seconds: 15),
);

  if (response.statusCode != 200) {
    return [];
  }

  final json = jsonDecode(response.body);

  return json['elements'] as List<dynamic>;
}