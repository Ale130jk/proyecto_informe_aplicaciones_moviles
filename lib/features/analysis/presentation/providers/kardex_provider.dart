import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/kardex_model.dart';

class KardexHistoryState {
  final bool isLoading;
  final List<KardexModel> sales;
  final List<KardexModel> movements;
  final String? errorMessage;

  KardexHistoryState({
    this.isLoading = true,
    this.sales = const [],
    this.movements = const [],
    this.errorMessage,
  });
}

final kardexHistoryProvider = NotifierProvider<KardexHistoryNotifier, KardexHistoryState>(() => KardexHistoryNotifier());

class KardexHistoryNotifier extends Notifier<KardexHistoryState> {
  @override
  KardexHistoryState build() {
    fetchHistory();
    return KardexHistoryState();
  }

  Future<void> fetchHistory() async {
    state = KardexHistoryState(isLoading: true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('kardex')
          .orderBy('date', descending: true)
          .get();
          
      final allRecords = snapshot.docs.map((doc) => KardexModel.fromMap(doc.data(), doc.id)).toList();
      final sales = allRecords.where((r) => r.reason == 'VENTA').toList();
      final movements = allRecords.where((r) => r.reason != 'VENTA').toList();

      state = KardexHistoryState(isLoading: false, sales: sales, movements: movements);
    } catch (e) {
      state = KardexHistoryState(isLoading: false, errorMessage: e.toString());
    }
  }
}