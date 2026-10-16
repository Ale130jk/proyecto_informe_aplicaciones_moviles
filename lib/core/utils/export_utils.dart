import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/products/domain/models/product_model.dart';
import '../../features/products/domain/models/category_model.dart';
import '../../features/operations/presentation/providers/purchase_assistant_provider.dart';

class ExportUtils {
  static Future<void> sendWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final nativeUrl = Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}');
    final webUrl = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}');

    try {
      await launchUrl(nativeUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        throw 'No se pudo abrir WhatsApp. Verifica si está instalado.';
      }
    }
  }

  static Future<void> sendCatalogWhatsApp(String phone, List<ProductModel> products) async {
    if (phone.length != 9 || int.tryParse(phone) == null) {
      throw 'El número debe contener exactamente 9 dígitos numéricos.';
    }

    StringBuffer message = StringBuffer();
    message.writeln('*LIBRERÍA SANGUI - Catálogo Disponible*');
    message.writeln('-----------------------------------');
    
    for (var p in products) {
      message.writeln('▪ ${p.name} | Cód: ${p.barcode}');
      message.writeln('  Stock: ${p.stock} uds.');
      message.writeln('-----------------------------------');
    }

    final finalPhone = '51$phone';
    
    final nativeUrl = Uri.parse('whatsapp://send?phone=$finalPhone&text=${Uri.encodeComponent(message.toString())}');
    final webUrl = Uri.parse('https://api.whatsapp.com/send?phone=$finalPhone&text=${Uri.encodeComponent(message.toString())}');

    try {
      await launchUrl(nativeUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        throw 'No se pudo abrir WhatsApp. Verifica si está instalado.';
      }
    }
  }

  static String _getCategoryName(String categoryId, List<CategoryModel> categories) {
    try {
      return categories.firstWhere((c) => c.id == categoryId).name;
    } catch (_) {
      return 'Sin Categoría';
    }
  }

  static Future<void> generateInventoryPDF(List<ProductModel> products, List<CategoryModel> categories) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateString = DateFormat('dd/MM/yyyy HH:mm').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('LIBRERÍA SANGUI', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange800)),
                  pw.Text('Reporte de Inventario', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Generado el: $dateString', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              headerHeight: 30,
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headers: ['Código', 'Producto', 'Categoría', 'Stock Disp.'],
              data: products.map((p) => [
                p.barcode,
                p.name,
                _getCategoryName(p.categoryId, categories), 
                p.stock.toString(), 
              ]).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Inventario_SANGUI_${now.millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<String?> generatePurchasePdf(List<PurchaseSuggestion> suggestions) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateString = DateFormat('dd/MM/yyyy HH:mm').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('LIBRERÍA SANGUI - ASISTENTE DE COMPRAS', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text('Sugerencia de Pedido - $dateString'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Producto', 'Stock Actual', 'Sugerido a Comprar'],
                data: suggestions.map((PurchaseSuggestion s) => [
                  s.product.name,
                  s.product.stock.toString(),
                  '+${s.suggestedQuantity}'
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Pedido_SANGUI.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<void> exportCatalogExcel(List<ProductModel> products, List<CategoryModel> categories) async {
    StringBuffer csvData = StringBuffer();
    
    csvData.writeln('Codigo;Producto;Categoria;Stock Minimo;Stock Actual');
    
    for (var p in products) {
      final cleanName = p.name.replaceAll(';', '');
      final categoryName = _getCategoryName(p.categoryId, categories);
      final cleanCategory = categoryName.replaceAll(';', '');
      
      csvData.writeln('${p.barcode};$cleanName;$cleanCategory;${p.minStock};${p.stock}');
    }

    final String csvString = '\uFEFF' + csvData.toString();
    final bytes = utf8.encode(csvString);
    
    final xFile = XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'text/csv',
      name: 'Resumen_Inventario_SANGUI.csv'
    );
    
    await Share.shareXFiles([xFile], text: 'Resumen de Inventario SANGUI');
  }

  static Future<void> shareCatalogPdf(List<ProductModel> products, List<CategoryModel> categories) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateString = DateFormat('dd/MM/yyyy HH:mm').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('LIBRERÍA SANGUI', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange800)),
                  pw.Text('Catálogo de Productos', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Actualizado al: $dateString', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              headerHeight: 30,
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headers: ['Código', 'Producto', 'Categoría', 'Stock Disp.'],
              data: products.map((p) => [
                p.barcode,
                p.name,
                _getCategoryName(p.categoryId, categories),
                p.stock.toString(),
              ]).toList(),
            ),
          ];
        },
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Catalogo_SANGUI.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '¡Hola! Te compartimos nuestro catálogo de productos actualizado de Librería SANGUI. 📚✨',
    );
  }
}