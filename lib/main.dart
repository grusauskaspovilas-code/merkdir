import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await loadProducts();
  await loadShoppingList();

  runApp(const MerkDirApp());
}

Future<void> showStoreNotification(
  String store,
  List<ShoppingItem> items,
) async {
  await notifications.show(
    id: 1,
    title: '🔔 $store in der Nähe',
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

class MerkDirApp extends StatelessWidget {
  const MerkDirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MerkDir')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => openAddProduct(context),
              child: const Text('Produkt hinzufügen'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShoppingListPage(),
                  ),
                );
              },
              child: const Text('Einkaufsliste'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => openFavorites(context),
              child: const Text('Favoriten'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NearbyStoresPage(),
                  ),
                );
              },
              child: const Text('📍 Geschäfte in der Nähe'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GpsTestPage(),
                  ),
                );
              },
              child: const Text('GPS Test'),
            ),
          ],
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
        const SnackBar(content: Text('Bitte Produktname eingeben')),
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
      SnackBar(content: Text('Gespeichert: $title')),
    );

    Navigator.pop(context);
  }

  String stars(int value) => '⭐' * value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produkt hinzufügen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Produktname',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Wein', child: Text('Wein')),
                DropdownMenuItem(value: 'Schokolade', child: Text('Schokolade')),
                DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
                DropdownMenuItem(value: 'Käse', child: Text('Käse')),
                DropdownMenuItem(value: 'Getränke', child: Text('Getränke')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => category = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: rating,
              decoration: const InputDecoration(
                labelText: 'Bewertung',
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
              decoration: const InputDecoration(
                labelText: 'Notizen',
                border: OutlineInputBorder(),
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
              label: const Text('Foto auswählen'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveProduct,
              child: const Text('Speichern'),
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
  String status = 'Klicken Sie auf die Schaltfläche, um Geschäfte zu finden';
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

  Future<void> findStoresAndItems() async {
    print('FIND STORES STARTED');
    
    setState(() {
      status = 'Suche nach Geschäften...';
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
      node["shop"~"supermarket|convenience"](around:200,$lat,$lon);
      way["shop"~"supermarket|convenience"](around:200,$lat,$lon);
      relation["shop"~"supermarket|convenience"](around:200,$lat,$lon);
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
        status = 'Geschäfte konnten nicht gefunden werden';
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
          return (tags['name'] ?? 'Unbekannter Laden').toString();
        })
        .toSet()
        .toList();

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
          ? 'Keine passenden Artikel für Geschäfte in der Nähe'
          : 'Passende Geschäfte gefunden';
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
          title: Text('🔔 $firstStore in der Nähe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Offene Einkäufe:'),
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
              child: const Text('Später'),
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
              child: const Text('Zur Einkaufsliste'),
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
        title: const Text('📍 Geschäfte in der Nähe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(status),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                debugPrint('BUTTON CLICKED');
                findStoresAndItems();
              },
              child: const Text('Geschäfte suchen'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoriten')),
      body: favoriteProducts.isEmpty
          ? const Center(child: Text('Noch keine Produkte gespeichert'))
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
                          product.category,
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
                                    stores: ['Beliebiges Geschäft'],
                                    priority: 'Normal',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einkaufsliste'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Produkt',
                border: OutlineInputBorder(),
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

          Wrap(
            children: [
              'Lidl',
              'Aldi',
              'Rewe',
              'Edeka',
              'Coop',
              'Migros',
              'Denner',
            ].map((store) {
              return SizedBox(
                width: 180,
                child: CheckboxListTile(
                  title: Text(store),
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
              );
            }).toList(),
          ),

          ElevatedButton(
            onPressed: addItem,
            child: const Text('+'),
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
                    onPressed: () {
                      setState(() {
                        shoppingList.removeAt(index);
                      });
                      saveShoppingList();
                    },
                  ),

                  value: item.bought,

                  onChanged: (value) {
                    setState(() {
                      item.bought = value ?? false;
                    });

                    saveShoppingList();
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

class GpsTestPage extends StatefulWidget {
  const GpsTestPage({super.key});

  @override
  State<GpsTestPage> createState() => _GpsTestPageState();
}

class _GpsTestPageState extends State<GpsTestPage> {
  String locationText = 'Noch keine Position';
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
        title: const Text('GPS Test'),
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
              (store) => Text('🏪 $store'),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: getLocation,
              child: const Text('Position prüfen'),
            ),
          ],
        ),
      ),
    );
  }
}