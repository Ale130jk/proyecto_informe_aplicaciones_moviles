import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_list_provider.dart';
import '../../domain/models/product_model.dart';
import '../../data/product_repository.dart';

class ProductFormState {
  final bool isScanning;
  final bool isLoading;
  final String? scannedBarcode;
  final String? errorMessage;
  final bool isSuccess;

  ProductFormState({
    this.isScanning = true,
    this.isLoading = false,
    this.scannedBarcode,
    this.errorMessage,
    this.isSuccess = false,
  });

  ProductFormState copyWith({
    bool? isScanning,
    bool? isLoading,
    String? scannedBarcode,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ProductFormState(
      isScanning: isScanning ?? this.isScanning,
      isLoading: isLoading ?? this.isLoading,
      scannedBarcode: scannedBarcode ?? this.scannedBarcode,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final productFormProvider = NotifierProvider<ProductFormNotifier, ProductFormState>(() => ProductFormNotifier());

class ProductFormNotifier extends Notifier<ProductFormState> {
  @override
  ProductFormState build() => ProductFormState();

  Future<void> processBarcode(String barcode) async {
    if (!state.isScanning || state.isLoading) return;
    state = state.copyWith(isScanning: false, isLoading: true, errorMessage: null);
    try {
      final repository = ref.read(productRepositoryProvider);
      final exists = await repository.checkBarcodeExists(barcode);
      if (exists) {
        state = state.copyWith(isLoading: false, isScanning: true, errorMessage: 'El código $barcode ya existe.');
      } else {
        state = state.copyWith(isLoading: false, scannedBarcode: barcode);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, isScanning: true, errorMessage: 'Error de red: $e');
    }
  }

  // ELIMINADA LA FUNCIÓN processAndCompressPhoto

  Future<bool> saveProduct({
    required String barcode,
    required String name,
    required String categoryId, 
    required int minStock,
    required int initialStock,
    required double price, 
  }) async {
    final String finalBarcode = barcode.isEmpty ? 'SANGUI-${DateTime.now().millisecondsSinceEpoch}' : barcode;
    state = state.copyWith(isLoading: true);

    final allProducts = ref.read(productListProvider).products;
    final nameExists = allProducts.any((p) => p.name.toLowerCase().trim() == name.toLowerCase().trim());
    
    if (nameExists) {
      state = state.copyWith(isLoading: false, errorMessage: 'El producto "$name" ya está registrado en el catálogo.');
      return false;
    }

    try {
      final repository = ref.read(productRepositoryProvider);
      final exists = await repository.checkBarcodeExists(finalBarcode);
      
      if (exists && barcode.isNotEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: 'El código $finalBarcode ya existe.');
        return false;
      }

      final newProduct = ProductModel(
        id: '',
        barcode: finalBarcode,
        name: name,
        categoryId: categoryId,
        minStock: minStock,
        stock: initialStock, 
        price: price, 
        imageUrl: '', // Siempre vacío, no usamos Storage
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await repository.createProduct(newProduct);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error: $e');
      return false;
    }
  }

  void resetScanner() {
    state = ProductFormState();
  }
}