import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/kardex_model.dart';
import '../../../products/domain/models/product_model.dart';

class ReportsState {
  final bool isLoading;
  final int totalOperations; 
  final int totalItemsSold;
  final List<MapEntry<String, int>> topSellingProducts;
  final String? errorMessage;

  ReportsState({
    this.isLoading = true,
    this.totalOperations = 0,
    this.totalItemsSold = 0,
    this.topSellingProducts = const [],
    this.errorMessage,
  });
}

final reportsProvider = NotifierProvider<ReportsNotifier, ReportsState>(() => ReportsNotifier());

class ReportsNotifier extends Notifier<ReportsState> {
  @override
  ReportsState build() {
    generateReport();
    return ReportsState();
  }

  Future<void> generateReport() async {
    state = ReportsState(isLoading: true);
    try {
      final firestore = FirebaseFirestore.instance;
      
      // 1. Traer TODOS los movimientos del Kardex para contar operaciones
      final allKardexSnapshot = await firestore.collection('kardex').get();
      
      // 2. Traer productos para resolver los nombres reales
      final productsSnapshot = await firestore.collection('products').get();
      final productsMap = {for (var doc in productsSnapshot.docs) doc.id: ProductModel.fromMap(doc.data(), doc.id).name};

      int operationsCount = allKardexSnapshot.docs.length;
      int itemsSold = 0;
      Map<String, int> productSales = {};

      // 3. Procesar datos
      for (var doc in allKardexSnapshot.docs) {
        final record = KardexModel.fromMap(doc.data(), doc.id);
        
        // Solo sumamos a ventas si el motivo es "VENTA"
        if (record.reason == 'VENTA') {
          itemsSold += record.quantity;
          
          final productName = productsMap[record.productId] ?? 'Producto Desconocido';
          productSales[productName] = (productSales[productName] ?? 0) + record.quantity;
        }
      }

      // 4. Ordenar Top 5
      final sortedTopProducts = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top5 = sortedTopProducts.take(5).toList();

      state = ReportsState(
        isLoading: false,
        totalOperations: operationsCount,
        totalItemsSold: itemsSold,
        topSellingProducts: top5,
      );
    } catch (e) {
      state = ReportsState(isLoading: false, errorMessage: 'Error al generar reporte: $e');
    }
  }
}