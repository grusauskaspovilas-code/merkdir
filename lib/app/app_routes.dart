import 'package:flutter/material.dart';

import '../models/notification_data.dart';
import '../pages/add_product_page.dart';
import '../pages/favorites_page.dart';
import '../pages/gps_test_page.dart';
import '../pages/home_page.dart';
import '../pages/nearby_stores_page.dart';
import '../pages/notification_page.dart';
import '../pages/settings_page.dart';
import '../pages/shopping_list_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String addProduct = '/add-product';
  static const String favorites = '/favorites';
  static const String nearbyStores = '/nearby-stores';
  static const String gpsTest = '/gps-test';
  static const String settings = '/settings';
  static const String shoppingList = '/shopping-list';
  static const String notification = '/notification';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case addProduct:
        return MaterialPageRoute(builder: (_) => const AddProductPage());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesPage());
      case nearbyStores:
        return MaterialPageRoute(builder: (_) => const NearbyStoresPage());
      case gpsTest:
        return MaterialPageRoute(builder: (_) => const GpsTestPage());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case shoppingList:
        return MaterialPageRoute(builder: (_) => const ShoppingListPage());
      case notification:
        final data = routeSettings.arguments;

        if (data is NotificationData) {
          return MaterialPageRoute(
            builder: (_) => NotificationPage(data: data),
          );
        }

        return MaterialPageRoute(builder: (_) => const HomePage());
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }
}
