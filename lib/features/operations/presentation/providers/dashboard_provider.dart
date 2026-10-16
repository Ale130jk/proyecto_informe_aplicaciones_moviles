import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../products/presentation/providers/product_list_provider.dart';
import '../../../analysis/domain/models/kardex_model.dart';

class DashboardState {
  final bool isLoading;
  final List<ProductModel> lowStockProducts;
  final List<KardexModel> recentMovements;
  final bool hasAlerts;
  final bool isSearching;
  final List<ProductModel> searchResults;

  DashboardState({
    this.isLoading = true,
    this.lowStockProducts = const [],
    this.recentMovements = const [],
    this.hasAlerts = false,
    this.isSearching = false,
    this.searchResults = const [],
  });

  DashboardState copyWith({
    bool? isLoading,
    List<ProductModel>? lowStockProducts,
    List<KardexModel>? recentMovements,
    bool? hasAlerts,
    bool? isSearching,
    List<ProductModel>? searchResults,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      recentMovements: recentMovements ?? this.recentMovements,
      hasAlerts: hasAlerts ?? this.hasAlerts,
      isSearching: isSearching ?? this.isSearching,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(() => DashboardNotifier());

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    fetchDashboardData();
    return DashboardState();
  }

  Future<void> fetchDashboardData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // CORRECCIÓN: 'createdAt' -> 'date' para respetar el nuevo KardexModel
      final kardexSnapshot = await firestore
          .collection('kardex')
          .orderBy('date', descending: true)
          .limit(3)
          .get();
          
      final recentKardex = kardexSnapshot.docs
          .map((doc) => KardexModel.fromMap(doc.data(), doc.id))
          .toList();

      final productsSnapshot = await firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();
          
      final allProducts = productsSnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();

      // CORRECCIÓN: currentStock -> stock en toda la lógica matemática
      final lowStock = allProducts.where((p) => p.stock <= p.minStock).toList();
      
      lowStock.sort((a, b) => 
        (a.stock / (a.minStock == 0 ? 1 : a.minStock))
        .compareTo(b.stock / (b.minStock == 0 ? 1 : b.minStock))
      );
      
      final top3LowStock = lowStock.take(3).toList();

      state = state.copyWith(
        isLoading: false,
        lowStockProducts: top3LowStock,
        recentMovements: recentKardex,
        hasAlerts: top3LowStock.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // Búsqueda rápida en el Dashboard
  Future<void> searchProductQuickly(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(isSearching: false, searchResults: []);
      return;
    }
    state = state.copyWith(isSearching: true);
    
    try {
      // Leemos de la RAM y aplicamos toLowerCase() estricto
      final allProducts = ref.read(productListProvider).products;
      
      final results = allProducts.where((p) => 
        p.isActive && 
        p.name.toLowerCase().contains(query.toLowerCase())
      ).take(4).toList();
          
      state = state.copyWith(isSearching: false, searchResults: results);
    } catch (e) {
      state = state.copyWith(isSearching: false, searchResults: []);
    }
  }
  void clearSearch() {
    state = state.copyWith(isSearching: false, searchResults: []);
  }
}