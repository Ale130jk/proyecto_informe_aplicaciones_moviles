import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../products/presentation/screens/product_register_screen.dart';
import '../../../products/presentation/screens/product_list_screen.dart';
import 'inventory_adjust_screen.dart';
import '../providers/dashboard_provider.dart';
import 'sales_register_screen.dart';
import '../../../analysis/presentation/screens/kardex_history_screen.dart';
import '../../../analysis/presentation/screens/reports_screen.dart';
import 'config_screen.dart';
import 'purchase_assistant_screen.dart';
import '../../../products/presentation/screens/export_catalog_screen.dart';
import '../../../products/domain/models/product_model.dart';
import '../../../products/presentation/providers/product_list_provider.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(dashboardProvider.notifier).fetchDashboardData(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Lógica del semáforo de colores para el stock
  Color _getStockColor(int currentStock, int minStock) {
    if (currentStock <= minStock) return Colors.red.shade700;
    if (currentStock <= minStock + 5) {
      return Colors.orange.shade700; // Margen de precaución
    }
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboardState = ref.watch(dashboardProvider);
    final catalogState = ref.watch(productListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Panel de Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      drawer: _buildSidebar(context, theme),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardProvider.notifier).fetchDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. CABECERA: Buscador Inteligente
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _debouncer.run(() {
                      ref
                          .read(dashboardProvider.notifier)
                          .searchProductQuickly(value.trim());
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar stock del producto...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),

                // 2. RESULTADOS DE BÚSQUEDA RÁPIDA
                if (_searchController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  if (dashboardState.isSearching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (dashboardState.searchResults.isEmpty)
                    const Center(
                      child: Text(
                        'No se encontraron productos.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dashboardState.searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = dashboardState.searchResults[index];
                          final stockColor = _getStockColor(
                            product.stock,
                            product.minStock,
                          );

                          return ListTile(
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Cód: ${product.barcode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: stockColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${product.stock}',
                                style: TextStyle(
                                  color: stockColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],

                    const SizedBox(height: 32),
                    if (dashboardState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (dashboardState.lowStockProducts.isEmpty)
                      Card(
                        color: Colors.green.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.green.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'Inventario estable. Todo bajo control.',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // ESTADO B: ALERTA DE STOCK (Aparece el título rojo y la lista)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Por Agotar',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade800),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: dashboardState.lowStockProducts.map((product) {
                                  final ratio = product.stock / (product.minStock == 0 ? 1 : product.minStock);
                                  final progressColor = ratio <= 0.3
                                      ? Colors.red
                                      : (ratio <= 0.7 ? Colors.orange : Colors.green);
                                      
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '${product.stock}/${product.minStock}',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: progressColor),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: ratio > 1 ? 1.0 : ratio,
                                          backgroundColor: Colors.grey.shade200,
                                          color: progressColor,
                                          minHeight: 8,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 32),

                // 4. PIE DE PANTALLA: Últimos Movimientos Kardex
                Text(
                  'Últimos Movimientos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (dashboardState.isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (!dashboardState.isLoading &&
                    dashboardState.recentMovements.isEmpty)
                  const Text(
                    'No hay movimientos recientes.',
                    style: TextStyle(color: Colors.grey),
                  ),
                if (!dashboardState.isLoading &&
                    dashboardState.recentMovements.isNotEmpty)
                 ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dashboardState.recentMovements.length,
                itemBuilder: (context, index) {
                  final movement = dashboardState.recentMovements[index];
                  
                  // 1. Resolvemos el nombre del producto consultando la RAM (latencia cero)
                  final catalogProducts = catalogState.products;
                  final productName = catalogProducts.firstWhere(
                    (p) => p.id == movement.productId,
                    orElse: () => ProductModel(id: '', name: 'Producto Desconocido', categoryId: '', price: 0, stock: 0)
                  ).name;

                  Color iconColor;
                  IconData iconData;
                  
                  if (movement.reason == 'VENTA') {
                    iconColor = Colors.green;
                    iconData = Icons.trending_up;
                  } else if (movement.operationType == 'INPUT') { // CORRECCIÓN: 'IN' -> 'INPUT'
                    iconColor = Colors.blue;
                    iconData = Icons.input_rounded;
                  } else {
                    iconColor = Colors.red;
                    iconData = Icons.trending_down;
                  }

                  // CORRECCIÓN: movement.createdAt -> movement.date
                  final timeString = DateFormat('dd MMM hh:mm a').format(movement.date); 

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: iconColor.withValues(alpha: 0.1),
                        child: Icon(iconData, color: iconColor),
                      ),
                      title: Text(
                        productName, // CORRECCIÓN: Usamos la variable resuelta arriba
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${movement.reason.replaceAll('_', ' ')} $timeString',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        // CORRECCIÓN: 'IN' -> 'INPUT' y quantityChanged -> quantity
                        '${movement.operationType == 'INPUT' ? '+' : '-'}${movement.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: iconColor,
                        ),
                      ),
                    ),
                  );
                },
              )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sidebar (Menú Lateral)
  Widget _buildSidebar(BuildContext context, ThemeData theme) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            color: theme.colorScheme.primary,
            child: const Column(
              children: [
                Icon(Icons.inventory_2_rounded, size: 64, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'SANGUI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Gestión JA-KAR',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.add_box_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Nuevo Producto'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductRegisterScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.inventory_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Catálogo General'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductListScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.sync_alt_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Ajuste Rápido (+/-)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryAdjustScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.shopping_cart_checkout_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text(
              'Registrar Venta',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalesRegisterScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.history_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text(
              'Kardex Historial',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KardexHistoryScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.bar_chart_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text(
              'Reportes de Ventas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            title: const Text(
              'Asistente de Compras',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PurchaseAssistantScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.ios_share_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text(
              'Exportar Catálogo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportCatalogScreen()),
              );
            },
          ),
          // Opciones de Cierre
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfigScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
