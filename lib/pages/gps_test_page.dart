import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/store_service.dart';

class GpsTestPage extends StatefulWidget {
  const GpsTestPage({super.key});

  @override
  State<GpsTestPage> createState() => _GpsTestPageState();
}

class _GpsTestPageState extends State<GpsTestPage> {
  String locationText = '';
  List<String> nearbyStores = [];

  Future<void> getLocation() async {
    print('GPS BUTTON PRESSED');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        locationText = 'GPS ist ausgeschaltet';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        locationText = 'GPS-Berechtigung verweigert';
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    
    print('LAT: ${position.latitude}');
    print('LON: ${position.longitude}');
    
    await findNearbyStores(
      position.latitude,
      position.longitude,
    );

    setState(() {
      locationText =
          'Latitude: ${position.latitude}\nLongitude: ${position.longitude}';
    });
  }

  Future<void> findNearbyStores(double lat, double lon) async {
  final query = """
  [out:json];
  (
    node["shop"~"supermarket|convenience"](around:5000,$lat,$lon);
    way["shop"~"supermarket|convenience"](around:5000,$lat,$lon);
    relation["shop"~"supermarket|convenience"](around:5000,$lat,$lon);
  );
  out center tags;
  """;

  final url = Uri.parse(
    'https://overpass-api.de/api/interpreter',
  );

  print(query);
  print('SENDING REQUEST');
  
  http.Response response;
  try {
    response = await http.post(
      url,
      headers: {
        'Content-Type': 'text/plain',
        'Accept': 'application/json',
        'User-Agent': 'MerkDir-App',
      },
      body: query,
    ).timeout(
      const Duration(seconds: 15),
    );

    print('STATUS: ${response.statusCode}');
    print(response.body);

  } catch (e) {
    print('HTTP ERROR: $e');

    setState(() {
      nearbyStores = ['HTTP ERROR: $e'];
    });

    return;
  }

  final data = jsonDecode(response.body);
  final elements = data['elements'] as List;

  setState(() {
    nearbyStores = elements
      .map<String>((element) {
        final tags = element['tags'] ?? {};
        return (tags['name'] ?? 'Unbekannter Laden').toString();
      })
      .toSet()
      .toList();
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.findStores,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              locationText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ...nearbyStores.map(
              (store) => ListTile(
                leading: const Icon(Icons.store),
                title: Text(store),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () async {
                  if (!availableStores.contains(store)) {
                    setState(() {
                      availableStores.add(store);
                    });

                    final prefs = await SharedPreferences.getInstance();

                    await prefs.setStringList(
                      'availableStores',
                      availableStores,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$store ${AppLocalizations.of(context)!.storeAdded}',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: getLocation,
              child: Text(
                AppLocalizations.of(context)!.checkPosition,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
