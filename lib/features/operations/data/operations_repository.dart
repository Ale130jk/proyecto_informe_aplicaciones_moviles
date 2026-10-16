import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../analysis/domain/models/kardex_model.dart';
import '../domain/models/cart_item_model.dart';

class OperationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<bool> adjustSingleProductStock({
    required String productId, 
    required String barcode, 
    required String productName,
    required String operationType, 
    required String reason, 
    required int quantity, 
    required String operatorId,
  }) async {
    try {
      final productRef = _firestore.collection('products').doc(productId);
      final kardexRef = _firestore.collection('kardex').doc();
      
      await _firestore.runTransaction((transaction) async {
        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists) throw Exception("El producto no existe");
        final currentStock = productSnapshot.data()?['stock'] as int? ?? 0;
        int newStock = currentStock;
        if (operationType == 'INPUT') {
          newStock += quantity;
        } else {
          if (currentStock < quantity) throw Exception("Stock insuficiente.");
          newStock -= quantity;
        }
      
        final kardexEntry = KardexModel(
          id: kardexRef.id,
          productId: productId,
          operationType: operationType, 
          quantity: quantity,
          previousStock: currentStock,
          newStock: newStock,
          reason: reason,
          date: DateTime.now(),
          operatorId: operatorId,
        );
        transaction.update(productRef, {
          'stock': newStock, 
          'updated_at': FieldValue.serverTimestamp()
        });
        transaction.set(kardexRef, kardexEntry.toMap());
      });
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<bool> processBulkSale({
    required List<CartItemModel> cartItems,
    required String operatorId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        Map<String, DocumentSnapshot> snapshots = {};
        
        for (var item in cartItems) {
          final ref = _firestore.collection('products').doc(item.product.id);
          snapshots[item.product.id] = await transaction.get(ref);
        }
        
        for (var item in cartItems) {
          final doc = snapshots[item.product.id];
          if (!doc!.exists) throw Exception("Producto ${item.product.name} no encontrado.");
          
          final data = doc.data() as Map<String, dynamic>?;
          // CORRECCIÓN: currentStock -> stock
          final currentStock = data?['stock'] as int? ?? 0;
          
          if (currentStock < item.quantity) {
            throw Exception("Stock insuficiente para ${item.product.name}. Disponible: $currentStock.");
          }
          
          final newStock = currentStock - item.quantity;
          final productRef = _firestore.collection('products').doc(item.product.id);
          final kardexRef = _firestore.collection('kardex').doc();
          final kardexMap = KardexModel(
            id: kardexRef.id,
            productId: item.product.id,
            operationType: 'OUTPUT', 
            quantity: item.quantity,
            previousStock: currentStock,
            newStock: newStock,
            reason: 'VENTA',
            date: DateTime.now(),
            operatorId: operatorId,
            unitPrice: item.price,
            totalPrice: item.price * item.quantity,
          ).toMap();
          transaction.update(productRef, {
            'stock': newStock, 
            'updated_at': FieldValue.serverTimestamp()
          });
          transaction.set(kardexRef, kardexMap);
        }
      });
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
final operationsRepositoryProvider = Provider((ref) => OperationsRepository());