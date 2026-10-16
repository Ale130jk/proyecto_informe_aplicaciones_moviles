import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../products/presentation/providers/product_list_provider.dart';
import '../../domain/models/kardex_model.dart';
import '../providers/kardex_provider.dart';

class KardexHistoryScreen extends ConsumerWidget {
  const KardexHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kardexHistoryProvider);
    final theme = Theme.of(context);
    final catalogState = ref.watch(productListProvider);
    final productsMap = {for (var p in catalogState.products) p.id: p.name};

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Kardex / Historial', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag), text: 'VENTAS'),
              Tab(icon: Icon(Icons.sync_alt), text: 'MOVIMIENTOS'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(kardexHistoryProvider.notifier).fetchHistory(),
            )
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(state.sales, isSale: true, productsMap: productsMap),
                  _buildList(state.movements, isSale: false, productsMap: productsMap),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<KardexModel> records, {required bool isSale, required Map<String, String> productsMap}) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSale ? Icons.receipt_long : Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No hay registros en esta categoría.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final timeString = DateFormat('dd/MM/yyyy hh:mm a').format(record.date);
        final productName = productsMap[record.productId] ?? 'Producto Desconocido';
        
        Color iconColor = Colors.grey;
        IconData iconData = Icons.help;
        
        if (record.operationType == 'INPUT') {
          iconColor = Colors.green.shade700;
          iconData = Icons.add_circle_outline;
        } else {
          iconColor = Colors.red.shade700;
          iconData = Icons.remove_circle_outline;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(iconData, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(timeString, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Motivo: ${record.reason.replaceAll('_', ' ')}', style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${record.operationType == 'INPUT' ? '+' : '-'}${record.quantity}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: iconColor),
                    ),
                    const SizedBox(height: 4),
                    Text('Stock Final: ${record.newStock}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}