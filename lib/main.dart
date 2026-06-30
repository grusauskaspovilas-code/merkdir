import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

String? lastNotifiedStore;
DateTime? lastNotificationTime;

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
Future<void> requestLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    return;
  }

  LocationPermission permission =
      await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();


  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await notifications.initialize(
    settings: const InitializationSettings(
      android: androidSettings,
    ),
  );

  await notifications
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.requestNotificationsPermission();
  
  await requestLocationPermission();
  await initializeService();
  await loadProducts();
  await loadShoppingList();
  await loadAvailableStores();
  await loadNotificationSettings();
  await loadSavedLanguage();

  runApp(const MerkDirApp());
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

        if (response.statusCode == 200) {
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

            final storeName =
              (tags['name'] ?? '').toString();

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

            if (distance > notificationDistance) {
              continue;
            }
            final matchingItems = <String>[];

            for (final itemJson in data ?? []) {
              final decoded = jsonDecode(itemJson);

              print(
                "${decoded['name']}  bought=${decoded['bought']}"
              );

              final bought = decoded['bought'] ?? false;

              if (bought) continue;

              final stores =
              List<String>.from(decoded['stores'] ?? []);

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

            if (matchingItems.isNotEmpty) {

              final now = DateTime.now();

              if (lastNotifiedStore == storeId &&
                  lastNotificationTime != null &&
                  now.difference(lastNotificationTime!).inMinutes < checkIntervalMinutes) {
                continue;
              }

              lastNotifiedStore = storeId;
              lastNotificationTime = now;

            print('MATCH FOUND IN $storeName');
            print(matchingItems);

            await showStoreNotification(
              storeName,
              matchingItems
                .map(
                  (e) => ShoppingItem(
                    name: e,
                    stores: [],
                    priority: 'normal',
                  ),
                )
                .toList(),
              );

              break;
            }
          }
        }

      } catch (e) {
        print('GPS ERROR: $e');
      }
    },
  );
}

Future<void> showStoreNotification(
  String store,
  List<ShoppingItem> items,
) async {
  await notifications.show(
    id: 1,
    title: '🔔 $store nearby',
    body: items
      .map((e) => e.name)
      .take(3)
      .join(', '),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'merkdir_channel',
        'MerkDir Erinnerungen',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );
}

class Product {
  final String title;
  final String category;
  final int rating;
  final String notes;
  final Uint8List? image;

  Product({
    required this.title,
    required this.category,
    required this.rating,
    required this.notes,
    required this.image,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'rating': rating,
      'notes': notes,
      'image': image == null ? null : base64Encode(image!),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      title: json['title'] ?? '',
      category: json['category'] ?? 'Wein',
      rating: json['rating'] ?? 5,
      notes: json['notes'] ?? '',
      image: json['image'] == null ? null : base64Decode(json['image']),
    );
  }
}

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
Locale currentLocale = const Locale('lt');

Future<void> loadSavedLanguage() async {
  final prefs = await SharedPreferences.getInstance();

  final lang = prefs.getString('language');

  if (lang != null) {
    currentLocale = Locale(lang);
  }
}

class MerkDirApp extends StatelessWidget {
  const MerkDirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: currentLocale,

      localizationsDelegates:
        AppLocalizations.localizationsDelegates,

      supportedLocales:
        AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: Text(
                details.exceptionAsString(),
              ),
            ),
          );
        };
        return child!;
      },
      title: 'MerkDir',

      theme: ThemeData(
        brightness: Brightness.dark,

        scaffoldBackgroundColor: const Color(0xFF1E1E1E),

        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFF8C00),
          secondary: const Color(0xFFFF8C00),
          surface: const Color(0xFF2A2A2A),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A2A2A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        cardColor: const Color(0xFF2A2A2A),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFFF8C00),
              width: 2,
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final quickProductController =
    TextEditingController();

  Uint8List? quickPhoto;

  void openAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductPage()),
    );
  }

  void openFavorites(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoritesPage()),
    );
  }
  Future<void> pickQuickPhoto() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (file == null) return;

    quickPhoto = await file.readAsBytes();

    setState(() {});

    await addQuickShoppingItem();
  }

  Future<List<String>?> selectStoresDialog(
  BuildContext context,
  ) async {
    final selectedStores = <String>[];

    return await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.selectStores,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: availableStores.map((store) {
                  return CheckboxListTile(
                    title: Text(store),
                    value: selectedStores.contains(store),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedStores.add(store);
                        } else {
                          selectedStores.remove(store);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    List<String>.from(availableStores),
                  );
                },
                child: Text(
                  AppLocalizations.of(context)!.allStores,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    selectedStores.isEmpty
                        ? List<String>.from(availableStores)
                        : selectedStores,
                  );
                },
                child: Text(
                  AppLocalizations.of(context)!.add,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> addQuickShoppingItem() async {
    if (quickProductController.text.trim().isEmpty &&
        quickPhoto == null) {
      return;
    }
    final stores = await selectStoresDialog(context);

    if (stores == null) return;

    shoppingList.add(
      ShoppingItem(
        name: quickProductController.text.trim().isEmpty
            ? '📷 Produktas'
            : quickProductController.text.trim(),
        stores: stores,
        priority: 'Normal',
      ),
    );

    saveShoppingList();

    quickProductController.clear();

    setState(() {
      quickPhoto = null;
    });
  }
  
  void addQuickFavorite() {
    if (quickProductController.text.trim().isEmpty &&
        quickPhoto == null) {
      return;
    }

    favoriteProducts.add(
      Product(
        title: quickProductController.text.trim().isEmpty
            ? '📷 Produktas'
            : quickProductController.text.trim(),
        category: '',
        rating: 5,
        notes: '',
        image: quickPhoto,
      ),
    );

    saveProducts();

    quickProductController.clear();

    setState(() {
      quickPhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MerkDir'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (value) async {
              final prefs = await SharedPreferences.getInstance();

              await prefs.setString(
                'language',
                value,
              );

              currentLocale = Locale(value);

              runApp(const MerkDirApp());
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'de',
                child: Text('🇩🇪 Deutsch'),
              ),
              const PopupMenuItem(
                value: 'en',
                child: Text('🇬🇧 English'),
              ),
              const PopupMenuItem(
                value: 'lt',
                child: Text('🇱🇹 Lietuvių'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
           

            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.quickAdd,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quickProductController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.shopping_basket,
                                color: Color(0xFFFF8C00),
                              ),
                              hintText:
                                AppLocalizations.of(context)!.productNameHint,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        IconButton(
                          iconSize: 40,
                          onPressed: pickQuickPhoto,
                          icon: const Icon(Icons.camera_alt),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: addQuickShoppingItem,
                            icon: Icon(Icons.shopping_cart),
                            label: Text(
                              AppLocalizations.of(context)!.toShoppingList,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: addQuickFavorite,
                            icon: Icon(Icons.star),
                            label: Text(
                              AppLocalizations.of(context)!.toFavorites,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ShoppingListPage(),
                          ),
                        );
                      },
                  child: Text(
                    AppLocalizations.of(context)!.shoppingList,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
              onPressed: () => openFavorites(context),
              child: Text(
                AppLocalizations.of(context)!.favorites,
              ),
            ),
            ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NearbyStoresPage(),
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.nearbyStores,
              ),
            ),
            ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GpsTestPage(),
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.searchStores,
              ),
            ),
            ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ),
                );
              },
              child: Text(
            AppLocalizations.of(context)!.settings,
          ),
            ),
            ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final titleController = TextEditingController();
  final notesController = TextEditingController();

  String category = 'Wein';
  int rating = 5;
  Uint8List? productImage;

  @override
  void dispose() {
    titleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();

    setState(() {
      productImage = bytes;
    });
  }

  void saveProduct() {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterProductName)),
      );
      return;
    }

    favoriteProducts.add(
      Product(
        title: title,
        category: category,
        rating: rating,
        notes: notesController.text.trim(),
        image: productImage,
      ),
    );

    saveProducts();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppLocalizations.of(context)!.saved} $title',
        ),
      ),
    );

    Navigator.pop(context);
  }

  String stars(int value) => '⭐' * value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.addProduct,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.productName,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.category,
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Wein',
                  child: Text(AppLocalizations.of(context)!.wine),
                ),
                DropdownMenuItem(
                  value: 'Schokolade',
                  child: Text(AppLocalizations.of(context)!.chocolate),
                ),
                DropdownMenuItem(
                  value: 'Snacks',
                  child: Text(AppLocalizations.of(context)!.snacks),
                ),
                DropdownMenuItem(
                  value: 'Käse',
                  child: Text(AppLocalizations.of(context)!.cheese),
                ),
                DropdownMenuItem(
                  value: 'Getränke',
                  child: Text(AppLocalizations.of(context)!.drinks),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => category = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: rating,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.rating,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('⭐')),
                DropdownMenuItem(value: 2, child: Text('⭐⭐')),
                DropdownMenuItem(value: 3, child: Text('⭐⭐⭐')),
                DropdownMenuItem(value: 4, child: Text('⭐⭐⭐⭐')),
                DropdownMenuItem(value: 5, child: Text('⭐⭐⭐⭐⭐')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => rating = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.notes,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            if (productImage != null)
              Image.memory(
                productImage!,
                height: 150,
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.photo),
              label: Text(
                AppLocalizations.of(context)!.selectPhoto,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveProduct,
              child: Text(
                AppLocalizations.of(context)!.save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('🔔 ${firstStore} ${AppLocalizations.of(context)!.nearby}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.openShopping),
              const SizedBox(height: 10),

              ...items.map(
                (item) => Text(
                  '${priorityEmoji(item.priority)} ${item.name}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.later),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShoppingListPage(),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.toShoppingList),
            ),
          ],
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

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String stars(int value) => '⭐' * value;

  Future<void> deleteProduct(int index) async {
    setState(() {
      favoriteProducts.removeAt(index);
    });

    await saveProducts();
  }

  String translateCategory(BuildContext context, String category) {
    switch (category) {
      case 'Wein':
        return AppLocalizations.of(context)!.wine;
      case 'Schokolade':
        return AppLocalizations.of(context)!.chocolate;
      case 'Snacks':
        return AppLocalizations.of(context)!.snacks;
      case 'Käse':
        return AppLocalizations.of(context)!.cheese;
      case 'Getränke':
        return AppLocalizations.of(context)!.drinks;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.favorites,
        ),
      ),
      body: favoriteProducts.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.noSavedProducts,))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteProducts.length,
              itemBuilder: (context, index) {
                final product = favoriteProducts[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.image != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              product.image!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          translateCategory(context, product.category),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stars(product.rating),
                          style: const TextStyle(fontSize: 18),
                        ),
                        if (product.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(product.notes),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.shopping_cart,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                shoppingList.add(
                                  ShoppingItem(
                                    name: product.title,
                                    stores: [AppLocalizations.of(context)!.anyStore],
                                    priority: AppLocalizations.of(context)!.normal,
                                  ),
                                );

                                saveShoppingList();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.title} zur Einkaufsliste hinzugefügt'),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => deleteProduct(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
      }

List<String> availableStores = [
  'Lidl',
  'Aldi',
  'Rewe',
  'Edeka',
  'Coop',
  'Migros',
  'Denner',
];

class ShoppingItem {
  String name;
  List<String> stores;
  bool bought;
  String priority;

  ShoppingItem({
    required this.name,
    required this.stores,
    required this.priority,
    this.bought = false,
  });
}

final List<ShoppingItem> shoppingList = [];

double notificationDistance = 30;
int checkIntervalMinutes = 1;

Future<void> saveNotificationSettings() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setDouble(
    'notificationDistance',
    notificationDistance,
  );

  await prefs.setInt(
    'checkIntervalMinutes',
    checkIntervalMinutes,
  );
}

Future<void> loadNotificationSettings() async {
  final prefs = await SharedPreferences.getInstance();

  notificationDistance =
      prefs.getDouble('notificationDistance') ?? 100;

  checkIntervalMinutes =
      prefs.getInt('checkIntervalMinutes') ?? 5;
}

Future<void> saveAvailableStores() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setStringList(
    'availableStores',
    availableStores,
  );
}

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

Future<void> loadAvailableStores() async {
  final prefs = await SharedPreferences.getInstance();

  final data = prefs.getStringList('availableStores');

  if (data == null) {
    availableStores = [
      'Lidl',
      'Aldi',
      'Rewe',
      'Edeka',
      'Coop',
      'Migros',
      'Denner',
    ];

    await saveAvailableStores();
    return;
  }

  availableStores = List<String>.from(data);
}

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final controller = TextEditingController();

  List<String> selectedStores = [];
  String selectedPriority = 'Normal';

  void addItem() {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      shoppingList.add(
        ShoppingItem(
          name: controller.text.trim(),
          stores: List.from(selectedStores),
          priority: selectedPriority,
        ),
      );
    });

    saveShoppingList();

    controller.clear();
    selectedStores.clear();
  }

  void addStore() {
    print('ADD STORE PRESSED');
    print(controller.text);

    if (controller.text.trim().isEmpty) return;

    setState(() {
      if (!availableStores.contains(controller.text.trim())) {
        availableStores.add(controller.text.trim());
        print('STORE ADDED');
      }
    });

    saveAvailableStores();

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.shoppingList,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.product,
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          DropdownButton<String>(     
            value: selectedPriority,
            items: const [
              DropdownMenuItem(
                value: 'Wichtig',
                child: Text('🔴 Wichtig'),
              ),
              DropdownMenuItem(
                value: 'Normal',
                child: Text('🟡 Normal'),
              ),
              DropdownMenuItem(
                value: 'Später',
                child: Text('⚪ Später'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedPriority = value!;
              });
            },
          ),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: addItem,
                  child: Text(
                    AppLocalizations.of(context)!.addProduct,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  onPressed: addStore,
                  child: Text(
                    AppLocalizations.of(context)!.addStore,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppLocalizations.of(context)!.stores,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(
            height: 180,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: availableStores.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
              ),
              itemBuilder: (context, index) {
                final store = availableStores[index];

                return Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        dense: true,
                        title: Text(
                          store,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: selectedStores.contains(store),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedStores.add(store);
                            } else {
                              selectedStores.remove(store);
                            }
                          });
                        },
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          availableStores.remove(store);
                          selectedStores.remove(store);
                        });

                        saveAvailableStores();
                      },
                    ),
                  ],
                );
              },
            ),
          ),



          Expanded(
            child: ListView.builder(
              itemCount: shoppingList.length,
              itemBuilder: (context, index) {
                final item = shoppingList[index];

                return CheckboxListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.bought
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                      color: item.bought ? Colors.grey : null,
                    ),
                  ),

                  subtitle: Text(
                    '🏪 ${item.stores.join(", ")}',
                  ),

                  secondary: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      setState(() {
                        shoppingList.removeAt(index);
                      });

                      await saveShoppingList();
                    },
                  ),

                  value: item.bought,

                  onChanged: (value) async {
                    setState(() {
                      item.bought = value ?? false;
                    });

                    await saveShoppingList();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.notificationSettings,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 20),

            Text(
              AppLocalizations.of(context)!.notificationDistance,
            ),

            DropdownButton<double>(
              value: notificationDistance,
              isExpanded: true,
              items: const [

                DropdownMenuItem(
                  value: 30,
                  child: Text('30 m'),
                ),

                DropdownMenuItem(
                  value: 50,
                  child: Text('50 m'),
                ),

                DropdownMenuItem(
                  value: 100,
                  child: Text('100 m'),
                ),

                DropdownMenuItem(
                  value: 200,
                  child: Text('200 m'),
                ),

                DropdownMenuItem(
                  value: 300,
                  child: Text('300 m'),
                ),

                DropdownMenuItem(
                  value: 500,
                  child: Text('500 m'),
                ),

                DropdownMenuItem(
                  value: 750,
                  child: Text('750 m'),
                ),

                DropdownMenuItem(
                  value: 1000,
                  child: Text('1000 m'),
                ),
              ],
              onChanged: (value) async {
                if (value == null) return;

                setState(() {
                  notificationDistance = value;
                });

                await saveNotificationSettings();
              },
            ),

            const SizedBox(height: 20),

            Text(
              AppLocalizations.of(context)!.checkInterval,
            ),

            DropdownButton<int>(
              value: checkIntervalMinutes,
              isExpanded: true,
              items: const [

                DropdownMenuItem(
                  value: 1,
                  child: Text('1 min'),
                ),

                DropdownMenuItem(
                  value: 2,
                  child: Text('2 min'),
                ),

                DropdownMenuItem(
                  value: 5,
                  child: Text('5 min'),
                ),

                DropdownMenuItem(
                  value: 10,
                  child: Text('10 min'),
                ),

                DropdownMenuItem(
                  value: 15,
                  child: Text('15 min'),
                ),

                DropdownMenuItem(
                  value: 30,
                  child: Text('30 min'),
                ),

                DropdownMenuItem(
                  value: 60,
                  child: Text('60 min'),
                ),
              ],
              onChanged: (value) async {
                if (value == null) return;

                setState(() {
                  checkIntervalMinutes = value;
                });

                await saveNotificationSettings();
              },
            ),

            const Divider(height: 40),

            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                AppLocalizations.of(context)!.aboutApp,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('ℹ️ MerkDir™'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.version} 1.0',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${AppLocalizations.of(context)!.createdBy}: Povilas Grušauskas',
                        ),
                        const SizedBox(height: 10),
                        const Text('© 2025 Povilas Grušauskas'),
                        Text(
                          AppLocalizations.of(context)!.allRightsReserved,
                        ),
                      ],
                    ),
                  ),
                );
                
              },
            )
          ],
        ),
      ),
      ),
    );
  }
}

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