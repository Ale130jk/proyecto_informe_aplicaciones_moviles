import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product_model.dart';
import '../providers/category_provider.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLowStock = product.stock <= product.minStock;
    
    // 1. SOLUCIÓN CATEGORÍA (Lectura segura de la base de datos)
    final categoryState = ref.watch(categoryProvider);
    final categories = categoryState.value ?? [];
    String categoryName = 'Sin Categoría';

    try {
      categoryName = categories.firstWhere((c) => c.id == product.categoryId).name;
    } catch (_) {
      categoryName = product.categoryId.isNotEmpty ? product.categoryId : 'Sin Categoría';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 2. SOLUCIÓN IMAGEN (Recuadro estético con inicial)
            Container(
              width: 80, 
              height: 80,
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown.shade200),
              ),
              child: Center(
                child: Text(
                  product.name.isNotEmpty ? product.name[0].toUpperCase() : '📦',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Text(categoryName, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    'Cód: ${product.barcode}', 
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isLowStock ? Colors.red.shade200 : Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Text('Stock', style: TextStyle(fontSize: 12, color: isLowStock ? Colors.red.shade700 : Colors.green.shade700)),
                  Text('${product.stock}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isLowStock ? Colors.red.shade700 : Colors.green.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}