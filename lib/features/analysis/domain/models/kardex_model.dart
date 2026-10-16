import 'package:cloud_firestore/cloud_firestore.dart';

class KardexModel {
  final String id;
  final String productId;
  final String operationType;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String reason;
  final DateTime date;
  final String operatorId;
  final double? unitPrice;
  final double? totalPrice; 

  KardexModel({
    required this.id,
    required this.productId,
    required this.operationType,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    required this.date,
    required this.operatorId,
    this.unitPrice,
    this.totalPrice,
  });

  KardexModel copyWith({
    String? id,
    String? productId,
    String? operationType,
    int? quantity,
    int? previousStock,
    int? newStock,
    String? reason,
    DateTime? date,
    String? operatorId,
    double? unitPrice,
    double? totalPrice,
  }) {
    return KardexModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      operationType: operationType ?? this.operationType,
      quantity: quantity ?? this.quantity,
      previousStock: previousStock ?? this.previousStock,
      newStock: newStock ?? this.newStock,
      reason: reason ?? this.reason,
      date: date ?? this.date,
      operatorId: operatorId ?? this.operatorId,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'operationType': operationType,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'date': Timestamp.fromDate(date),
      'operatorId': operatorId,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory KardexModel.fromMap(Map<String, dynamic> map, String documentId) {
    return KardexModel(
      id: documentId,
      productId: map['productId'] ?? '',
      operationType: map['operationType'] ?? 'OUTPUT',
      quantity: map['quantity'] ?? 0,
      previousStock: map['previousStock'] ?? 0,
      newStock: map['newStock'] ?? 0,
      reason: map['reason'] ?? '',
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      operatorId: map['operatorId'] ?? 'Sistema',
      unitPrice: map['unitPrice'] != null ? (map['unitPrice'] as num).toDouble() : null,
      totalPrice: map['totalPrice'] != null ? (map['totalPrice'] as num).toDouble() : null,
    );
  }
}