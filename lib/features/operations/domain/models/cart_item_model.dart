import '../../../products/domain/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;
  final double price; // <-- Nuevo campo para el precio dinámico de la venta

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.price = 0.0,
  });

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    double? price,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}