import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../services/product_service.dart';

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
