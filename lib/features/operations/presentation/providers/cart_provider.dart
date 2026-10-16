import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cart_item_model.dart';
import '../../../products/domain/models/product_model.dart';
import '../../data/operations_repository.dart';
import '../../../products/presentation/providers/product_list_provider.dart';

class CartState {
  final List<CartItemModel> items;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final List<ProductModel> searchResults;

  CartState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.searchResults = const [],
  });

  CartState copyWith({List<CartItemModel>? items, bool? isLoading, String? errorMessage, bool? isSuccess, List<ProductModel>? searchResults}) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(() => CartNotifier());

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => CartState();

  Future<void> searchProductForSale(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: []);
      return;
    }
    try {
      final allProducts = ref.read(productListProvider).products;
      final results = allProducts.where((p) => p.isActive && p.name.toLowerCase().contains(query.toLowerCase())).take(4).toList();
      state = state.copyWith(searchResults: results);
    } catch (_) {}
  }

  void addProductToCart(ProductModel product) {
    final List<CartItemModel> currentItems = List.from(state.items);
    final existingIndex = currentItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      final currentQty = currentItems[existingIndex].quantity;
      if (currentQty < product.stock) {
        currentItems[existingIndex] = currentItems[existingIndex].copyWith(quantity: currentQty + 1);
      } else {
        state = state.copyWith(errorMessage: 'Stock máximo alcanzado.');
        return;
      }
    } else {
      if (product.stock > 0) {
        // Fijamos precio 0.0 obligatoriamente porque es Kardex físico
        currentItems.add(CartItemModel(product: product, quantity: 1, price: 0.0)); 
      } else {
        state = state.copyWith(errorMessage: '${product.name} no tiene stock.');
        return;
      }
    }
    state = state.copyWith(items: currentItems, searchResults: []);
  }

  void updateQuantity(String productId, int delta) {
    final List<CartItemModel> currentItems = List.from(state.items);
    final index = currentItems.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      final item = currentItems[index];
      final newQty = item.quantity + delta;

      if (newQty <= 0) {
        currentItems.removeAt(index);
      } else if (newQty <= item.product.stock) {
        currentItems[index] = item.copyWith(quantity: newQty);
      } else {
        state = state.copyWith(errorMessage: 'Stock insuficiente.');
        return;
      }
      state = state.copyWith(items: currentItems);
    }
  }

  Future<bool> processCheckout() async {
    if (state.items.isEmpty) return false;
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(operationsRepositoryProvider);
      await repository.processBulkSale(cartItems: state.items, operatorId: 'Admin');
      state = CartState(isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}