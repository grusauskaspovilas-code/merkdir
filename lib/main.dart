import 'package:flutter/material.dart';

void main() {
  runApp(const MerkDirApp());
}

class Product {
  final String title;
  final String category;
  final int rating;
  final String notes;

  Product({
    required this.title,
    required this.category,
    required this.rating,
    required this.notes,
  });
}

final List<Product> favoriteProducts = [];

class MerkDirApp extends StatelessWidget {
  const MerkDirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      appBar: AppBar(
        title: const Text('MerkDir'),
      ),
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
              onPressed: () => openFavorites(context),
              child: const Text('Favoriten'),
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

  @override
  void dispose() {
    titleController.dispose();
    notesController.dispose();
    super.dispose();
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
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gespeichert: $title')),
    );

    Navigator.pop(context);
  }

  String stars(int value) => '⭐' * value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produkt hinzufügen'),
      ),
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

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  String stars(int value) => '⭐' * value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriten'),
      ),
      body: favoriteProducts.isEmpty
          ? const Center(child: Text('Noch keine Produkte gespeichert'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteProducts.length,
              itemBuilder: (context, index) {
                final product = favoriteProducts[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite),
                    title: Text(product.title),
                    subtitle: Text(
                      '${product.category} · ${stars(product.rating)}\n${product.notes}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}