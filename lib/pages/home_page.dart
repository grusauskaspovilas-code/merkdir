import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/merkdir_app.dart';
import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../models/shopping_item.dart';
import '../services/language_service.dart';
import '../services/product_service.dart';
import '../services/shopping_list_service.dart';
import '../services/store_service.dart';
import 'add_product_page.dart';
import 'favorites_page.dart';
import 'gps_test_page.dart';
import 'nearby_stores_page.dart';
import 'settings_page.dart';
import 'shopping_list_page.dart';

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
