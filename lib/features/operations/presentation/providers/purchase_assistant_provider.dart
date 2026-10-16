import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../analysis/domain/models/kardex_model.dart';

class PurchaseSuggestion {
  final ProductModel product;
  final int soldLast30Days;
  final int suggestedQuantity;

  PurchaseSuggestion({
    required this.product,
    required this.soldLast30Days,
    required this.suggestedQuantity,
  });
}

class PurchaseAssistantState {
  final bool isLoading;
  final List<PurchaseSuggestion> suggestions;
  final String? errorMessage;

  PurchaseAssistantState({
    this.isLoading = true,
    this.suggestions = const [],
    this.errorMessage,
  });
}

final purchaseAssistantProvider =
    NotifierProvider<PurchaseAssistantNotifier, PurchaseAssistantState>(
      () => PurchaseAssistantNotifier(),
    );

class PurchaseAssistantNotifier extends Notifier<PurchaseAssistantState> {
  @override
  PurchaseAssistantState build() {
    generateSuggestions();
    return PurchaseAssistantState();
  }

  Future<void> generateSuggestions() async {
    state = PurchaseAssistantState(isLoading: true);
    try {
      final firestore = FirebaseFirestore.instance;
      final productsSnap = await firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();
      final products = productsSnap.docs
          .map((d) => ProductModel.fromMap(d.data(), d.id))
          .toList();

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // CORRECCIÓN: Filtramos por el nuevo campo 'date' del Kardex
      final kardexSnap = await firestore
          .collection('kardex')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
          )
          .get();

      Map<String, int> salesMap = {};

      for (var doc in kardexSnap.docs) {
        final record = KardexModel.fromMap(doc.data(), doc.id);
        if (record.reason == 'VENTA') {
          // CORRECCIÓN: Usamos record.quantity
          salesMap[record.productId] =
              (salesMap[record.productId] ?? 0) + record.quantity;
        }
      }

      List<PurchaseSuggestion> suggestionsList = [];

      for (var product in products) {
        final sold = salesMap[product.id] ?? 0;
        int suggestToBuy = 0;

        // CORRECCIÓN: Usamos product.stock en lugar de currentStock
        if (product.stock < sold) {
          suggestToBuy = sold - product.stock;
        } else if (product.stock < product.minStock) {
          suggestToBuy = product.minStock - product.stock;
        }

        if (suggestToBuy > 0) {
          suggestionsList.add(
            PurchaseSuggestion(
              product: product,
              soldLast30Days: sold,
              suggestedQuantity: suggestToBuy,
            ),
          );
        }
      }

      suggestionsList.sort(
        (a, b) => b.suggestedQuantity.compareTo(a.suggestedQuantity),
      );

      state = PurchaseAssistantState(
        isLoading: false,
        suggestions: suggestionsList,
      );
    } catch (e) {
      state = PurchaseAssistantState(
        isLoading: false,
        errorMessage: 'Error de predicción: $e',
      );
    }
  }
}
