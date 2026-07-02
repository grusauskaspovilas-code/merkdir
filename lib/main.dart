import 'package:flutter/material.dart';

import 'app/merkdir_app.dart';
import 'services/background_service.dart';
import 'services/language_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/product_service.dart';
import 'services/settings_service.dart';
import 'services/shopping_list_service.dart';
import 'services/store_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

await initializeNotificationService();
await requestLocationPermission();

await loadNotificationSettings();

await initializeService();

await loadProducts();
await loadShoppingList();
await loadAvailableStores();
await loadSavedLanguage();
  runApp(const MerkDirApp());
}
