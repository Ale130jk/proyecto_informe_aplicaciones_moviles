import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/product_list_provider.dart';
import '../providers/product_form_provider.dart';

class ProductRegisterScreen extends ConsumerStatefulWidget {
  const ProductRegisterScreen({super.key});

  @override
  ConsumerState<ProductRegisterScreen> createState() =>
      _ProductRegisterScreenState();
}

class _ProductRegisterScreenState extends ConsumerState<ProductRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _minStockController = TextEditingController();
  final _initialStockController = TextEditingController();

  bool _modeSelected = false;
  bool _isManualMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(productListProvider).products.isEmpty) {
        ref.read(productListProvider.notifier).fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _minStockController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_isManualMode && _barcodeController.text.isEmpty) {
      _barcodeController.text = 'INT-${DateTime.now().millisecondsSinceEpoch}';
    }

    if (_formKey.currentState!.validate()) {
      final minStock = int.tryParse(_minStockController.text.trim());
      final initialStock = int.tryParse(_initialStockController.text.trim());

      if (minStock == null ||
          minStock < 0 ||
          minStock > 99999 ||
          initialStock == null ||
          initialStock < 0 ||
          initialStock > 99999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingrese cantidades válidas (máximo 9999)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ref
          .read(productFormProvider.notifier)
          .saveProduct(
            barcode: _barcodeController.text.trim(),
            name: _nameController.text.trim(),
            categoryId: _categoryController.text.trim(),
            minStock: minStock,
            initialStock: initialStock,
            price: 0.0,
          )
          .then((success) {
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto guardado con éxito'),
                  backgroundColor: Colors.green,
                ),
              );
              ref
                  .read(productListProvider.notifier)
                  .fetchProducts(isRefresh: true);
              Navigator.pop(context);
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productFormProvider);
    final theme = Theme.of(context);
    final catalogState = ref.watch(productListProvider);
    final existingCategories = catalogState.products
        .map((p) => p.categoryId)
        .toSet()
        .toList();

    ref.listen<ProductFormState>(productFormProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
      if (!_isManualMode &&
          next.scannedBarcode != null &&
          _barcodeController.text.isEmpty) {
        _barcodeController.text = next.scannedBarcode!;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuevo Producto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (_modeSelected)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Cambiar Modo',
              onPressed: () {
                setState(() {
                  _modeSelected = false;
                });
                _barcodeController.clear();
                ref.read(productFormProvider.notifier).resetScanner();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: !_modeSelected
            ? _buildModeSelection(theme)
            : (!_isManualMode &&
                  state.isScanning &&
                  state.scannedBarcode == null)
            ? _buildScannerView(theme)
            : _buildFormView(state, theme, existingCategories),
      ),
    );
  }

  Widget _buildModeSelection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Cómo registrarás el producto?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          _SelectionCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Usar Cámara',
            subtitle: 'Escanea el código de barras',
            color: Colors.blue.shade700,
            onTap: () => setState(() {
              _modeSelected = true;
              _isManualMode = false;
            }),
          ),
          const SizedBox(height: 24),
          _SelectionCard(
            icon: Icons.keyboard_alt_outlined,
            title: 'Ingreso Manual',
            subtitle: 'Escribe el código y usa contadores',
            color: Colors.orange.shade800,
            onTap: () => setState(() {
              _modeSelected = true;
              _isManualMode = true;
            }),
          ),
        ],
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
                ref
                    .read(productFormProvider.notifier)
                    .processBarcode(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Container(
                width: 250,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Text(
            'Apunta al código de barras',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildFormView(
    ProductFormState state,
    ThemeData theme,
    List<String> existingCategories,
  ) {
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IgnorePointer(
              ignoring: _isManualMode,
              child: TextFormField(
                controller: _barcodeController,
                readOnly: _isManualMode,
                decoration: InputDecoration(
                  labelText: 'Código de Barras / ID',
                  prefixIcon: const Icon(Icons.qr_code),
                  filled: true,
                  fillColor: _isManualMode
                      ? Colors.grey.shade200
                      : Colors.white,
                  helperText: _isManualMode
                      ? ''
                      : 'Puedes modificar el código escaneado si lo deseas',
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'El código es obligatorio'
                    : null,
              ),
            ),

            const SizedBox(
              height: 24,
            ), 

            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del Producto',
                prefixIcon: Icon(Icons.edit),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Requerido' : null,
            ),

            const SizedBox(height: 16),

            // CAMPO PREDICTIVO DE CATEGORÍA (Blindado)
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (existingCategories.isEmpty) {
                  return const Iterable<String>.empty();
                }
                if (textEditingValue.text.isEmpty) {
                  return existingCategories;
                }
                return existingCategories.where(
                  (category) => category.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (String selection) {
                FocusScope.of(context).unfocus();
              },
              fieldViewBuilder:
                  (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    textEditingController.addListener(() {
                      _categoryController.text = textEditingController.text;
                    });
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category),
                        hintText: 'Ej: Cuadernos',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Requerido'
                          : null,
                    );
                  },
            ),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Stock Mínimo',
                      helperText: 'Alerta de escasez',
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _initialStockController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Stock Inicial',
                      helperText: 'Cantidad física',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: state.isLoading ? null : _submitForm,
                child: state.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'GUARDAR PRODUCTO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
