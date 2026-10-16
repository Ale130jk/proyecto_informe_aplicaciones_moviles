import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkBarcodeExists(String barcode) async {
    final snapshot = await _firestore
        .collection('products')
        .where('barcode', isEqualTo: barcode)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ELIMINADA LA FUNCIÓN uploadProductImage

  Future<String> createProduct(ProductModel product) async {
    final docRef = _firestore.collection('products').doc();
    await docRef.set(product.toMap());
    return docRef.id;
  }

  Future<Map<String, dynamic>> getProductsPaginated({
    DocumentSnapshot? lastDocument,
    String searchQuery = '',
    int limit = 15,
  }) async {
    Query query = _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('name');

    if (searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff');
    }
    query = query.limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    final products = snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    return {
      'products': products,
      'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    };
  }
}
final productRepositoryProvider = Provider((ref) => ProductRepository());