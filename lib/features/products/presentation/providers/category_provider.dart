import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/category_model.dart';

final categoryProvider = StreamProvider<List<CategoryModel>>((ref) {
  return FirebaseFirestore.instance.collection('categories').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => CategoryModel.fromMap(doc.data(), doc.id)).toList();
  });
});