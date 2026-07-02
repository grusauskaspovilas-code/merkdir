import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../app/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../models/notification_data.dart';
import '../models/shopping_item.dart';
import '../services/notification_service.dart';
import '../services/shopping_list_service.dart';

class NearbyStoresPage extends StatefulWidget {
  const NearbyStoresPage({super.key});

  @override
  State<NearbyStoresPage> createState() => _NearbyStoresPageState();
}

class _NearbyStoresPageState extends State<NearbyStoresPage> {
  String status = '';
  Map<String, List<ShoppingItem>> storeMatches = {};
  bool notificationShown = false;

  @override
    void initState() {
    super.initState();

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    ).listen((Position position) async {
      await findStoresAndItems();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (status.isEmpty) {
      status = AppLocalizations.of(context)!.findStoresHint;
    }
  }

  Future<void> findStoresAndItems() async {
    print('FIND STORES STARTED');
    
    setState(() {
      status = AppLocalizations.of(context)!.searchingStores;
      storeMatches = {};
    });
    

    final position = await Geolocator.getCurrentPosition();

    print('LAT: ${position.latitude}');
    print('LON: ${position.longitude}');

    final lat = position.latitude;
    final lon = position.longitude;

    final query = """
    [out:json];
    (
      node["shop"~"supermarket|convenience"](around:500,$lat,$lon);
      way["shop"~"supermarket|convenience"](around:500,$lat,$lon);
      relation["shop"~"supermarket|convenience"](around:500,$lat,$lon);
    );
    out center tags;
    """;
    print('QUERY CREATED');
    print('SENDING REQUEST');

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
    print('RESPONSE RECEIVED');
    print('STATUS: ${response.statusCode}');
    print(response.body);

    if (response.statusCode != 200) {
      setState(() {
        status = AppLocalizations.of(context)!.storesNotFound;
      });
      return;
    }

    final data = jsonDecode(response.body);
    final elements = data['elements'] as List;

    print('ELEMENTS COUNT: ${elements.length}');

    if (elements.isNotEmpty) {
      print(elements.first);
    }

    print('ELEMENTS COUNT: ${elements.length}');

    final stores = elements
        .map<String>((element) {
          final tags = element['tags'] ?? {};
          return (tags['name'] ?? '').toString();
        })
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
      
      print('STORES FOUND:');
        for (final s in stores) {
          print(s);
        }  

    final Map<String, List<ShoppingItem>> matches = {};

    for (final store in stores) {
      final items = shoppingList.where((item) {
        if (item.bought) return false;

        final storeName = store.toLowerCase();

        final itemStores =
          item.stores.map((s) => s.toLowerCase()).toList();

        return itemStores.any(
          (s) => storeName.contains(s) || s.contains(storeName),
        );
      }).toList();

      if (items.isNotEmpty) {
        matches[store] = items;
      }
    }

    setState(() {
      storeMatches = matches;
      status = matches.isEmpty
          ? AppLocalizations.of(context)!.noNearbyMatches
          : AppLocalizations.of(context)!.matchingStores;
    });
    if (matches.isEmpty) {
      notificationShown = false;
    }
    if (matches.isNotEmpty &&
      mounted &&
      !notificationShown) {
      print('ENTERED MATCH BLOCK');
      final firstStore = matches.keys.first;
      final items = matches[firstStore]!;
      notificationShown = true;

      print('NOTIFICATION SENT');

      await showStoreNotification(
        firstStore,
        items,
      );

      Navigator.pushNamed(
        context,
        AppRoutes.notification,
        arguments: NotificationData(
          store: firstStore,
          items: items,
        ),
      );
    }
  }
  String priorityEmoji(String priority) {
    if (priority == 'Wichtig') return '🔴';
    if (priority == 'Normal') return '🟡';
    return '⚪';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.nearbyStores,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              status.isEmpty
                ? AppLocalizations.of(context)!.findStoresHint
                : status,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                debugPrint('BUTTON CLICKED');
                findStoresAndItems();
              },
              child: Text(
                AppLocalizations.of(context)!.searchStores,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: storeMatches.entries.map((entry) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏪 ${entry.key}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...entry.value.map(
                            (item) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Text(priorityEmoji(item.priority)),
                              title: Text(item.name),
                              subtitle: Text(item.stores.join(', ')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
