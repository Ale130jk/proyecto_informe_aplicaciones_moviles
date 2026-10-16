import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/export_utils.dart';
import '../providers/product_list_provider.dart';
import '../providers/category_provider.dart';

class ExportCatalogScreen extends ConsumerStatefulWidget {
  const ExportCatalogScreen({super.key});

  @override
  ConsumerState<ExportCatalogScreen> createState() => _ExportCatalogScreenState();
}

class _ExportCatalogScreenState extends ConsumerState<ExportCatalogScreen> {

  void _shareCatalogPdf(List products, List categories) async {
    try {
      // Notificación rápida de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando archivo PDF...'), duration: Duration(seconds: 1)),
      );
      await ExportUtils.shareCatalogPdf(products.cast(), categories.cast());
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lectura de los Providers (Con protección contra nulos para las categorías)
    final categoryState = ref.watch(categoryProvider);
    final categories = categoryState.value ?? [];
    
    final state = ref.watch(productListProvider);
    final theme = Theme.of(context);
    final products = state.products;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Exportar Catálogo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: state.isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange.shade300),
                      const SizedBox(height: 16),
                      const Text('No hay datos en el catálogo para exportar.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Enviar a Clientes', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Comparte el catálogo completo en formato PDF mediante WhatsApp u otras redes.', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () => _shareCatalogPdf(products, categories),
                                icon: const Icon(Icons.share),
                                label: const Text('COMPARTIR CATÁLOGO', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366), // Color WhatsApp
                                  padding: const EdgeInsets.symmetric(vertical: 16)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text('2. Documentos Gerenciales', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Descarga un reporte formal de tu inventario actual para contabilidad o socios.', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () => ExportUtils.exportCatalogExcel(products, categories),
                                icon: const Icon(Icons.table_chart_rounded),
                                label: const Text('DESCARGAR EXCEL (.CSV)', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 16)),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => ExportUtils.generateInventoryPDF(products, categories),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('IMPRIMIR PDF GERENCIAL', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(vertical: 16)),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}