import 'dart:async';
import 'dart:convert';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shopping_item.dart';
import 'geofence_service.dart';
import 'notification_service.dart';
import 'reminder_service.dart';
import 'reminder_storage_service.dart';
import 'settings_service.dart';
import 'store_state_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      foregroundServiceNotificationId: 999,
      initialNotificationTitle: 'MerkDir',
      initialNotificationContent: 'Background service running',
    ),
    iosConfiguration: IosConfiguration(),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  print('BACKGROUND SERVICE STARTED');

  Timer.periodic(
    Duration(minutes: checkIntervalMinutes),
    (timer) async {
      print('BACKGROUND TIMER RUNNING');

      try {
        await loadNotificationSettings();

        print(
          'Distance: $notificationDistance m | Interval: $checkIntervalMinutes min',
        );

        final position = await Geolocator.getCurrentPosition();

        print('LAT: ${position.latitude}');
        print('LON: ${position.longitude}');

        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();

        final data = prefs.getStringList('shoppingList');

        print("BACKGROUND ITEMS: ${data?.length}");
        print(data);
        print('SHOPPING ITEMS: ${data?.length ?? 0}');

        if (data == null || data.isEmpty) {
          print('NO SHOPPING ITEMS - SKIP OVERPASS');
          return;
        }

        final lat = position.latitude;
        final lon = position.longitude;

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
        ).timeout(
          const Duration(seconds: 15),
        );

        print('STORE STATUS: ${response.statusCode}');

        if (response.statusCode != 200) {
          return;
        }

        final json = jsonDecode(response.body);
        final elements = json['elements'] as List;

        print('STORES FOUND: ${elements.length}');

        elements.sort((a, b) {
          double getDistance(dynamic element) {
            double? lat2;
            double? lon2;

            if (element['type'] == 'node') {
              lat2 = (element['lat'] as num?)?.toDouble();
              lon2 = (element['lon'] as num?)?.toDouble();
            } else if (element['center'] != null) {
              lat2 = (element['center']['lat'] as num?)?.toDouble();
              lon2 = (element['center']['lon'] as num?)?.toDouble();
            }

            if (lat2 == null || lon2 == null) {
              return 999999;
            }

            return Geolocator.distanceBetween(
              lat,
              lon,
              lat2,
              lon2,
            );
          }

          return getDistance(a).compareTo(getDistance(b));
        });

        for (final element in elements) {
          final tags = element['tags'] ?? {};
          final storeName = (tags['name'] ?? '').toString();

          if (storeName.isEmpty) continue;

          double? storeLat;
          double? storeLon;

          if (element['type'] == 'node') {
            storeLat = (element['lat'] as num?)?.toDouble();
            storeLon = (element['lon'] as num?)?.toDouble();
          } else if (element['center'] != null) {
            storeLat = (element['center']['lat'] as num?)?.toDouble();
            storeLon = (element['center']['lon'] as num?)?.toDouble();
          }

          if (storeLat == null || storeLon == null) {
            continue;
          }

          final distance = Geolocator.distanceBetween(
            lat,
            lon,
            storeLat,
            storeLon,
          );

          print('DISTANCE TO $storeName: ${distance.toStringAsFixed(0)} m');

          final storeId = element['id'].toString();
          final state = StoreStateService.getState(storeId);

          state.lockedUntil ??=
              await ReminderStorageService.loadLockedUntil(storeId);

          if (ReminderService.isLocked(state.lockedUntil)) {
            print('STORE LOCKED: $storeName');
            continue;
          }

          if (state.lockedUntil != null &&
              !ReminderService.isLocked(state.lockedUntil)) {
            state.lockedUntil = null;
            await ReminderStorageService.clearLockedUntil(storeId);
          }

          if (distance > notificationDistance) {
            continue;
          }

          final matchingItems = <String>[];

          for (final itemJson in data) {
            final decoded = jsonDecode(itemJson);

            print("${decoded['name']}  bought=${decoded['bought']}");

            final bought = decoded['bought'] ?? false;

            if (bought) continue;

            final stores = List<String>.from(decoded['stores'] ?? []);

            String normalizedStore = storeName.toLowerCase();

            if (normalizedStore.contains('voi')) {
              normalizedStore = 'migros';
            }

            if (normalizedStore.contains('migrolino')) {
              normalizedStore = 'migros';
            }

            if (normalizedStore.contains('coop pronto')) {
              normalizedStore = 'coop';
            }

            if (normalizedStore.contains('aldi suisse')) {
              normalizedStore = 'aldi';
            }

            print('STORE MATCH CHECK: $storeName -> $normalizedStore');

            final matches = stores.any(
              (s) => normalizedStore.contains(
                s.toLowerCase(),
              ),
            );

            if (matches) {
              matchingItems.add(decoded['name']);
            }
          }

          if (matchingItems.isEmpty) {
            continue;
          }

          if (!GeofenceService.shouldNotify(
            state: state,
            distance: distance,
            notificationDistance: notificationDistance,
          )) {
            continue;
          }

          print('MATCH FOUND IN $storeName');
          print(matchingItems);

          await showStoreNotification(
            storeName,
            matchingItems
                .map(
                  (e) => ShoppingItem(
                    name: e,
                    stores: const [],
                    priority: 'normal',
                  ),
                )
                .toList(),
            distance: distance,
          );

          break;
        }
      } catch (e) {
        print('GPS ERROR: $e');
      }
    },
  );
}