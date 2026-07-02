import 'dart:convert';
import 'dart:typed_data';

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
