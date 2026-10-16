import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/stock_update_provider.dart';
import '../../../products/presentation/providers/product_list_provider.dart';
import '../../../products/domain/models/product_model.dart';

class InventoryAdjustScreen extends ConsumerStatefulWidget {
  const InventoryAdjustScreen({super.key});

  @override
  ConsumerState<InventoryAdjustScreen> createState() => _InventoryAdjustScreenState();
}

class _InventoryAdjustScreenState extends ConsumerState<InventoryAdjustScreen> {
  final _quantityController = TextEditingController();
  String _operationType = 'INPUT'; 
  String _reason = 'COMPRA_PROVEEDOR';
  
  final List<String> _inReasons = ['COMPRA_PROVEEDOR', 'AJUSTE_SOBRANTE', 'DEVOLUCION_CLIENTE'];
  final List<String> _outReasons = ['AJUSTE_MERMA', 'USO_INTERNO'];

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submitAdjustment() async {
   final qty = int.tryParse(_quantityController.text.trim());
   if (qty == null || qty <= 0 || qty > 999999) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingrese una cantidad válida (máximo 999,999)'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    
    final success = await ref.read(stockUpdateProvider.notifier).processAdjustment(
      operationType: _operationType,
      reason: _reason,
      quantity: qty,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kardex y Stock actualizados con éxito'), backgroundColor: Colors.green),
      );
    }
  }

  void _showManualSearch(BuildContext context, WidgetRef ref) {
    final products = ref.read(productListProvider).products;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Buscar Producto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Autocomplete<ProductModel>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<ProductModel>.empty();
                      }
                      return products.where((ProductModel product) {
                        return product.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    displayStringForOption: (ProductModel option) => option.name,
                    onSelected: (ProductModel selection) {
                      Navigator.pop(context); // Cerramos el buscador
                      // EN LUGAR DEL DIALOG, LLAMAMOS AL MISMO EVENTO DEL ESCÁNER:
                      ref.read(stockUpdateProvider.notifier).fetchProductByBarcode(selection.barcode);
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Escribe el nombre del producto...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockUpdateProvider);
    final theme = Theme.of(context);
    
    ref.listen<StockUpdateState>(stockUpdateProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: theme.colorScheme.error));
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuste de Stock Rápido'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar producto manualmente',
            onPressed: () => _showManualSearch(context, ref),
          ),
          if (state.selectedProduct != null)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner), 
              onPressed: () => ref.read(stockUpdateProvider.notifier).resetScanner()
            ),
        ],
      ),
      body: SafeArea(
        child: state.isScanning
            ? _buildScannerView(theme)
            : _buildAdjustmentForm(state, theme),
      ),
    );
  }

  Widget _buildScannerView(ThemeData theme) {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            for (final barcode in capture.barcodes) {
              if (barcode.rawValue != null) {
                ref.read(stockUpdateProvider.notifier).fetchProductByBarcode(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            child: Center(
              child: Container(
                width: 250, height: 150,
                decoration: BoxDecoration(border: Border.all(color: Colors.orange, width: 3), borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 40, left: 0, right: 0, 
          child: Text('Escanea el producto a ajustar', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
        ),
      ],
    );
  }

  Widget _buildAdjustmentForm(StockUpdateState state, ThemeData theme) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.selectedProduct == null) return const SizedBox.shrink();
    
    final product = state.selectedProduct!;
final reasonsList = _operationType == 'INPUT' ? _inReasons : _outReasons;
    if (!reasonsList.contains(_reason)) _reason = reasonsList.first; 
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Código: ${product.barcode}', style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                    child: Text('Stock Actual: ${product.stock}', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          Text('Tipo de Movimiento', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'INPUT', label: Text('ENTRADA (+)')),
              ButtonSegment(value: 'OUTPUT', label: Text('SALIDA (-)')),
            ],
            selected: {_operationType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _operationType = newSelection.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return _operationType == 'INPUT' ? Colors.green.shade100 : Colors.red.shade100;
                }
                return Colors.transparent;
              }),
            ),
          ),
          const SizedBox(height: 24),
          
          DropdownButtonFormField<String>(
            value: _reason,
            decoration: const InputDecoration(labelText: 'Motivo / Razón de Auditoría', prefixIcon: Icon(Icons.fact_check_outlined)),
            items: reasonsList.map((String reason) {
              return DropdownMenuItem(value: reason, child: Text(reason.replaceAll('_', ' ')));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() => _reason = newValue!);
            },
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(3)],
            decoration: const InputDecoration(labelText: 'Cantidad a modificar', prefixIcon: Icon(Icons.numbers)),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _submitAdjustment,
              icon: const Icon(Icons.save),
              label: const Text('CONFIRMAR AJUSTE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: _operationType == 'INPUT' ? Colors.green.shade700 : Colors.red.shade700
              ),
            ),
          ),
        ],
      ),
    );
  }
}