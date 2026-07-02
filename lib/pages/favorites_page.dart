import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/shopping_item.dart';
import '../services/product_service.dart';
import '../services/shopping_list_service.dart';

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
