import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/export_utils.dart';
import '../providers/purchase_assistant_provider.dart';

class PurchaseAssistantScreen extends ConsumerStatefulWidget {
  const PurchaseAssistantScreen({super.key});

  @override
  ConsumerState<PurchaseAssistantScreen> createState() => _PurchaseAssistantScreenState();
}

class _PurchaseAssistantScreenState extends ConsumerState<PurchaseAssistantScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOrderViaWhatsApp(List<PurchaseSuggestion> list) async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el número del proveedor', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Construcción del mensaje predefinido (Tu lógica original intacta)
    StringBuffer message = StringBuffer();
    message.writeln('Hola, solicito el siguiente pedido para *Librería SANGUI*:');
    message.writeln('-----------------------------------');
    for (var item in list) {
      message.writeln('${item.suggestedQuantity} uds. de ${item.product.name}');
    }
    message.writeln('-----------------------------------');
    message.writeln('Quedo atento a la confirmación y precios.');

    try {
      await ExportUtils.sendWhatsApp(_phoneController.text.trim(), message.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseAssistantProvider); 
    final theme = Theme.of(context); 

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Asistente de Compras', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(purchaseAssistantProvider.notifier).generateSuggestions(), 
          ),
        ],
      ),
      body: state.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null 
              ? Center(child: Text(state.errorMessage!, style: const TextStyle(color: Colors.red)))
              : state.suggestions.isEmpty 
                  ? _buildEmptyState(theme) // DISEÑO VISUAL MEJORADO
                  : _buildActiveState(state.suggestions, theme), // TU LISTA Y PANEL RESTAURADOS
    );
  }

  // ====================================================================
  // ESTADO A: INVENTARIO ÓPTIMO (Empty State Visual)
  // ====================================================================
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_rounded, size: 80, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Inventario Saludable!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'El stock de tus productos está en niveles óptimos. No hay sugerencias de compra en este momento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  const Text('Productos en alerta: 0', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // ESTADO B: ALERTAS DE COMPRA Y PANEL WHATSAPP (Lógica original)
  // ====================================================================
  Widget _buildActiveState(List<PurchaseSuggestion> suggestions, ThemeData theme) {
    return Column(
      children: [
        // Cabecera de información
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: const Row(
            children: [
              Icon(Icons.auto_graph, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Basado en las ventas de los últimos 30 días y alertas de stock mínimo.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        // Lista de Sugerencias
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: suggestions.length, 
            itemBuilder: (context, index) {
              final item = suggestions[index]; 
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                  ),
                  title: Text(
                    item.product.name, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stock actual: ${item.product.stock}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)), 
                        Text('Vendido últimos 30d: ${item.soldLast30Days}', style: const TextStyle(fontSize: 12)), 
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Comprar', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        Text(
                          '+${item.suggestedQuantity}', 
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // PANEL DE WHATSAPP AL PIE DE PÁGINA RESTAURADO
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _phoneController, 
                  keyboardType: TextInputType.phone, 
                  decoration: const InputDecoration(
                    labelText: 'Número de WhatsApp del Proveedor',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '+51 999 888 777', 
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _sendOrderViaWhatsApp(suggestions), 
                  icon: const Icon(Icons.send),
                  label: const Text('ENVIAR PEDIDO POR WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}