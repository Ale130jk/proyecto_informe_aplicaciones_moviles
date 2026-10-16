import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../providers/product_list_provider.dart';
import '../widgets/product_card.dart';
import '../../../../core/utils/export_utils.dart';
import '../../domain/models/product_model.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).fetchProducts();
    }
  }

  // MENÚ EMERGENTE DE EXPORTACIÓN (Similar a la selección en Registrar Producto)
  void _showExportOptions(BuildContext context, List<ProductModel> products) {
    // Bloqueo de seguridad: Si no hay productos, no se abre nada.
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos en el catálogo para exportar.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange)
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          // Ajuste para que el teclado del celular no tape la pantalla al escribir el WhatsApp
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
            left: 24, right: 24, top: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Opciones de Exportación', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // OPCIÓN 1: WHATSAPP
              const Text('1. Enviar Catálogo por WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 12),
              _WhatsAppInputRow(products: products),
              
              const Divider(height: 48),
              
              // OPCIÓN 2 y 3: EXCEL / PDF
              const Text('2. Descargar Resumen Gerencial', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // CORRECCIÓN: Agregamos [] como segundo parámetro requerido
                        ExportUtils.exportCatalogExcel(products, []); 
                      },
                      icon: const Icon(Icons.table_chart),
                      label: const Text('EXCEL'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // CORRECCIÓN: Agregamos [] como segundo parámetro requerido
                        ExportUtils.generateInventoryPDF(products, []); 
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo General', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          // BOTÓN PRINCIPAL QUE DESPLIEGA EL MENÚ
          IconButton(
            icon: const Icon(Icons.picture_as_pdf), // Se mantiene el ícono que solicitaste
            tooltip: 'Exportar Catálogo',
            onPressed: () => _showExportOptions(context, state.products),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // EL BUSCADOR ORIGINAL INTACTO
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _debouncer.run(() {
                    ref.read(productListProvider.notifier).searchProducts(value.trim());
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar producto por nombre...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: state.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(productListProvider.notifier).searchProducts('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            // LA LISTA DE PRODUCTOS ORIGINAL INTACTA
            Expanded(
              child: state.isInitialLoading
                  ? const ShimmerLoader()
                  : state.products.isEmpty
                  ? const Center(child: Text('No se encontraron productos.'))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(productListProvider.notifier).fetchProducts(isRefresh: true),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.products.length + (state.isFetchingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.products.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final product = state.products[index];
                          return ProductCard(product: product);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// WIDGET AISLADO: Campo de texto de WhatsApp con botón de envío
// =====================================================================
class _WhatsAppInputRow extends StatefulWidget {
  final List<ProductModel> products;
  const _WhatsAppInputRow({required this.products});

  @override
  State<_WhatsAppInputRow> createState() => _WhatsAppInputRowState();
}

class _WhatsAppInputRowState extends State<_WhatsAppInputRow> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendWhatsApp() async {
    final phone = _phoneController.text.trim();
    
    // Validación estricta: Solo permite avanzar si hay exactamente 9 dígitos
    if (phone.length == 9) {
      try {
        await ExportUtils.sendCatalogWhatsApp(phone, widget.products);
        if (mounted) Navigator.pop(context); // Cierra el menú al enviar
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    } else {
      // Mensaje de error si el número es inválido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El número debe tener exactamente 9 dígitos.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 9, // Fuerza a que no se puedan escribir más de 9 números
            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Bloquea letras o símbolos
            decoration: InputDecoration(
              hintText: 'Ej: 987654321',
              prefixText: '+51  ',
              counterText: '', // Oculta el contador "0/9" para que se vea más limpio
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 56,
          width: 56,
          child: FilledButton(
            onPressed: _sendWhatsApp,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366), // Color verde oficial de WhatsApp
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ),
      ],
    );
  }
}