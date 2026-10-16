import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reportes de Ventas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar Reporte',
            onPressed: () => ref.read(reportsProvider.notifier).generateReport(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(child: Text(state.errorMessage!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. TARJETAS DE MÉTRICAS GENERALES (Corregido para Kardex Físico)
                     Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Total Movimientos',
                              value: '${state.totalOperations}', // CORRECCIÓN: Antes decía totalItemsSold
                              icon: Icons.swap_horiz_rounded,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _MetricCard(
                              title: 'Unidades Vendidas',
                              value: '${state.totalItemsSold}',
                              icon: Icons.inventory_2_rounded,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // 2. RANKING DE PRODUCTOS MÁS VENDIDOS
                      Text('Top 5 - Más Vendidos', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (state.topSellingProducts.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: Text('Aún no hay ventas registradas.', style: TextStyle(color: Colors.grey))),
                          ),
                        )
                      else
                        Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.topSellingProducts.length,
                            // CORRECCIÓN: Damos 16px de espacio transparente entre cada elemento
                            separatorBuilder: (_, __) => const Divider(height: 16, color: Colors.transparent),
                            itemBuilder: (context, index) {
                              final product = state.topSellingProducts[index];
                              
                              Widget leadingWidget;
                              if (index == 0) {
                                leadingWidget = const Icon(Icons.emoji_events, color: Colors.amber, size: 32);
                              } else if (index == 1) {
                                leadingWidget = const Icon(Icons.emoji_events, color: Colors.grey, size: 32);
                              } else if (index == 2) {
                                leadingWidget = const Icon(Icons.emoji_events, color: Colors.brown, size: 32);
                              } else {
                                leadingWidget = CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey.shade200,
                                  child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                );
                              }
                              
                              return ListTile(
                                // CORRECCIÓN: Agregamos Padding interno a la tarjeta
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: leadingWidget,
                                title: Text(product.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text('${product.value} uds.', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

// Widget auxiliar para las tarjetas
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
          ],
        ),
      ),
    );
  }
}