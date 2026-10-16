import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product_model.dart';

class ProductListState {
  final List<ProductModel> products;
  final bool isInitialLoading;
  final bool isFetchingMore; // Mantenido para que la UI no marque error
  final bool hasMore; // Mantenido para que la UI no marque error
  final String searchQuery;
  final String? errorMessage;

  ProductListState({
    this.products = const [],
    this.isInitialLoading = true,
    this.isFetchingMore = false,
    this.hasMore = false, // Falso porque ahora cargamos el catálogo completo en RAM
    this.searchQuery = '',
    this.errorMessage,
  });

  ProductListState copyWith({
    List<ProductModel>? products,
    bool? isInitialLoading,
    bool? isFetchingMore,
    bool? hasMore,
    String? searchQuery,
    String? errorMessage,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final productListProvider = NotifierProvider<ProductListNotifier, ProductListState>(() {
  return ProductListNotifier();
});

class ProductListNotifier extends Notifier<ProductListState> {
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  ProductListState build() {
    // 1. Limpiamos la memoria si el Provider se destruye
    ref.onDispose(() {
      _subscription?.cancel();
    });

    // 2. Retrasamos la escucha a Firebase una fracción de segundo.
    // Esto permite que el build() termine y el Provider nazca (se inicialice) correctamente.
    Future.microtask(() {
      _listenToProducts();
    });

    // 3. Retornamos el estado base inicial (por defecto ya tiene isInitialLoading = true)
    return ProductListState();
  }

  // MÉTODO NÚCLEO: Escucha activa de Firestore a la RAM
  void _listenToProducts() {
    // Ya no hacemos "state = ..." aquí arriba para evitar el "Bad state"
    
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots() // Esto crea un túnel abierto con Firebase
        .listen((snapshot) {
      
      final products = snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();

      state = state.copyWith(
        products: products,
        isInitialLoading: false,
        errorMessage: null,
      );
    }, onError: (error) {
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: 'Error al sincronizar el catálogo: $error',
      );
    });
  }

  void searchProducts(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
  }
  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isInitialLoading: true);
      _listenToProducts(); 
    }
  }
}