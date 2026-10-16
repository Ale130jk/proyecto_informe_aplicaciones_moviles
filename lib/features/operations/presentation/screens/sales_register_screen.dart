import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../../core/utils/debouncer.dart';
import '../providers/cart_provider.dart';

class SalesRegisterScreen extends ConsumerStatefulWidget {
  const SalesRegisterScreen({super.key});

  @override
  ConsumerState<SalesRegisterScreen> createState() => _SalesRegisterScreenState();
}

class _SalesRegisterScreenState extends ConsumerState<SalesRegisterScreen> {
  String _lastScanned = '';
  DateTime _lastScannedTime = DateTime.now();
  bool _isManualMode = false;
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);
    final theme = Theme.of(context);

    // 1. ESCUCHADOR CORREGIDO: Solo lanza mensajes de error, ya no cierra la pantalla.
    ref.listen<CartState>(cartProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red));
        ref.read(cartProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Registrar Venta', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(_isManualMode ? Icons.qr_code_scanner : Icons.search),
            onPressed: () => setState(() => _isManualMode = !_isManualMode),
          ),
        ],
      ),
      body: Column(
        children: [
          // ZONA DE INGRESO
          if (_isManualMode)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      _debouncer.run(() => ref.read(cartProvider.notifier).searchProductForSale(val.trim()));
                    },
                    decoration: const InputDecoration(labelText: 'Buscar producto por nombre...', prefixIcon: Icon(Icons.search)),
                  ),
                  if (state.searchResults.isNotEmpty)
                    Card(
                      child: Column(
                        children: state.searchResults.map((p) => ListTile(
                          title: Text(p.name),
                          subtitle: Text('Stock disponible: ${p.stock}'),
                          trailing: const Icon(Icons.add_circle, color: Colors.green),
                          onTap: () {
                            ref.read(cartProvider.notifier).addProductToCart(p);
                            _searchController.clear();
                          },
                        )).toList(),
                      ),
                    ),
                ],
              ),
            )
          else
            SizedBox(
              height: 180,
              child: MobileScanner(
                onDetect: (capture) {
                  final barcode = capture.barcodes.first.rawValue;
                  if (barcode != null) {
                    final now = DateTime.now();
                    if (barcode != _lastScanned || now.difference(_lastScannedTime).inSeconds > 2) {
                      _lastScanned = barcode;
                      _lastScannedTime = now;
                      FirebaseFirestore.instance.collection('products')
                          .where('barcode', isEqualTo: barcode).where('isActive', isEqualTo: true).limit(1).get()
                          .then((snap) {
                        if (snap.docs.isNotEmpty) {
                          final prod = snap.docs.first;
                          ref.read(cartProvider.notifier).addProductToCart(ProductModel.fromMap(prod.data(), prod.id));
                        }
                      });
                    }
                  }
                },
              ),
            ),

          // LISTA DEL CARRITO
          Expanded(
            child: state.items.isEmpty
                ? const Center(child: Text('Carrito vacío.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                                    Text('Stock actual: ${item.product.stock}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.remove, color: Colors.red), onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, -1)),
                                  Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, 1)),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // BOTÓN PROCESAR VENTA (Protegido contra doble clic)
          if (state.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity, height: 50,
                child: FilledButton.icon(
                  onPressed: state.isLoading 
                    ? null 
                    : () async {
                        final success = await ref.read(cartProvider.notifier).processCheckout();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Venta procesada con éxito'), backgroundColor: Colors.green)
                          );
                          Navigator.pop(context);
                        }
                      },
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                  icon: state.isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle),
                  label: Text(
                    state.isLoading ? 'PROCESANDO...' : 'PROCESAR VENTA', 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}