import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/operations_repository.dart';
// Para buscar el producto
import '../../../products/domain/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockUpdateState {
  final bool isScanning;
  final bool isLoading;
  final ProductModel? selectedProduct;
  final String? errorMessage;

  StockUpdateState({
    this.isScanning = true,
    this.isLoading = false,
    this.selectedProduct,
    this.errorMessage,
  });

  StockUpdateState copyWith({bool? isScanning, bool? isLoading, ProductModel? selectedProduct, String? errorMessage}) {
    return StockUpdateState(
      isScanning: isScanning ?? this.isScanning,
      isLoading: isLoading ?? this.isLoading,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      errorMessage: errorMessage, // Nullable para limpiar errores
    );
  }
}

final stockUpdateProvider = NotifierProvider<StockUpdateNotifier, StockUpdateState>(() => StockUpdateNotifier());

class StockUpdateNotifier extends Notifier<StockUpdateState> {
  @override
  StockUpdateState build() => StockUpdateState();

  Future<void> fetchProductByBarcode(String barcode) async {
    if (!state.isScanning || state.isLoading) return;

    state = state.copyWith(isScanning: false, isLoading: true, errorMessage: null);

    try {
      // Reutilizamos el repositorio de productos para buscar por código de barras
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final product = ProductModel.fromMap(doc.data(), doc.id);
        state = state.copyWith(isLoading: false, selectedProduct: product);
      } else {
        state = state.copyWith(isLoading: false, isScanning: true, errorMessage: 'Producto no encontrado o inactivo.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, isScanning: true, errorMessage: 'Error al buscar: $e');
    }
  }

Future<bool> processAdjustment({
    required String operationType,
    required String reason,
    required int quantity,
  }) async {
    if (state.selectedProduct == null) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(operationsRepositoryProvider);
      await repository.adjustSingleProductStock(
        // CORRECCIÓN: Quitamos el '!' extra al final de id
        productId: state.selectedProduct!.id,
        barcode: state.selectedProduct!.barcode,
        productName: state.selectedProduct!.name,
        operationType: operationType,
        reason: reason,
        quantity: quantity,
        operatorId: 'jesus', // Operador logueado auditando la acción
      );
      
      // Reiniciamos el estado tras el éxito
      state = StockUpdateState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void resetScanner() {
    state = StockUpdateState();
  }
}