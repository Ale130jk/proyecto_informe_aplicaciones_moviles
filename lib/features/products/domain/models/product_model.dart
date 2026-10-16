import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final String barcode;
  final String imageUrl;
  final double price;
  final int stock;
  final int minStock;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.barcode = '',
    this.imageUrl = '',
    required this.price,
    required this.stock,
    this.minStock = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? barcode,
    String? imageUrl,
    double? price,
    int? stock,
    int? minStock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'barcode': barcode,
      'image_url': imageUrl,
      'price': price,
      'stock': stock,
      'min_stock': minStock,
      'isActive': isActive,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      id: documentId,
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      barcode: map['barcode'] ?? '',
      imageUrl: map['image_url'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      minStock: map['min_stock'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: map['created_at'] != null ? (map['created_at'] as Timestamp).toDate() : null,
      updatedAt: map['updated_at'] != null ? (map['updated_at'] as Timestamp).toDate() : null,
    );
  }
}