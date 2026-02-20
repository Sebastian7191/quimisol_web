import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/dashboard_models.dart';

/// ===========================================================================
/// EXPORT SERVICE – REPORTES (PDF + EXCEL) BASADO EN RANGO REAL
/// ===========================================================================

class ExportService {
  ExportService._();

  // =======================================================================
  // 🔥 FUNCIONES AUXILIARES
  // =======================================================================

  /// Carga todos los items completos desde Firestore
  static Future<List<_PedidoCompleto>> cargarPedidosCompletos(
      List<PedidoMini> pedidosMini) async {
    final fs = FirebaseFirestore.instance;
    final List<_PedidoCompleto> result = [];

    for (final p in pedidosMini) {
      final doc = await fs.collection("pedidos").doc(p.id).get();
      if (!doc.exists) continue;

      final data = doc.data()!;
      final items = <_ItemVenta>[];

      if (data["items"] is List) {
        for (final it in (data["items"] as List)) {
          if (it is Map<String, dynamic>) {
            items.add(
              _ItemVenta(
                name: (it["name"] ?? "").toString(),
                qty: (it["qty"] ?? 0) as num,
                price: (it["price"] ?? 0).toDouble(),
              ),
            );
          }
        }
      }

      result.add(_PedidoCompleto(
        id: p.id,
        codigo: p.codigo,
        direccion: p.direccion,
        departamento: p.departamento,
        estado: p.estado,
        createdAt: p.createdAt,
        total: p.total,
        repartidor: p.repartidorNombre,
        items: items,
      ));
    }

    return result;
  }

  // =======================================================================
  // 🔥 EXPORTACIÓN GENERAL – EXCEL (CON FILTROS CORRECTOS)
  // =======================================================================

  static Future<void> exportAllExcel(DashboardStats stats) async {
    final excel = Excel.createExcel();

    // 📌 cargar pedidos completos filtrados por rango
    final pedidosCompletos =
        await cargarPedidosCompletos(stats.pedidosFiltrados);

    final ventas = _agruparVentas(pedidosCompletos);

    // -------------------------------------------------------------
    // HOJA: PEDIDOS
    // -------------------------------------------------------------
    final pedidosSheet = excel['Pedidos'];
    pedidosSheet.appendRow([
      'Código',
      'Dirección',
      'Departamento',
      'Estado',
      'Fecha',
      'Total',
      'Repartidor',
    ]);

    for (final p in pedidosCompletos) {
      pedidosSheet.appendRow([
        p.codigo,
        p.direccion,
        p.departamento,
        p.estado,
        p.createdAt.toIso8601String(),
        p.total.toStringAsFixed(2),
        p.repartidor,
      ]);
    }

    // -------------------------------------------------------------
    // HOJA: PRODUCTOS
    // -------------------------------------------------------------
    final prodSheet = excel['Productos'];
    prodSheet.appendRow(['Nombre', 'Stock', 'Unidad', 'Precio', 'Almacén']);

    for (final p in stats.productosDelAlmacen) {
      prodSheet.appendRow([
        p.nombre,
        p.stock,
        p.unidad,
        p.precio.toStringAsFixed(2),
        p.almacenNombre
      ]);
    }

    // -------------------------------------------------------------
    // HOJA: MÁS VENDIDOS
    // -------------------------------------------------------------
    final masSheet = excel['MasVendidos'];
    masSheet.appendRow(['Producto', 'Cantidad', 'Ventas (Bs)']);

    for (final v in ventas.masVendidos) {
      masSheet.appendRow([v.name, v.qty, v.total.toStringAsFixed(2)]);
    }

    // -------------------------------------------------------------
    // HOJA: MENOS VENDIDOS
    // -------------------------------------------------------------
    final menosSheet = excel['MenosVendidos'];
    menosSheet.appendRow(['Producto', 'Stock', 'Unidad', 'Precio']);

    for (final p in ventas.menosVendidos(stats.productosDelAlmacen)) {
      menosSheet.appendRow([
        p.nombre,
        p.stock,
        p.unidad,
        p.precio.toStringAsFixed(2),
      ]);
    }

    // -------------------------------------------------------------
    // HOJA: LISTADO COMPLETO DE VENTAS
    // -------------------------------------------------------------
    final vendidosSheet = excel['Vendidos'];
    vendidosSheet.appendRow(['Producto', 'Cantidad', 'Ventas (Bs)']);

    for (final v in ventas.listado) {
      vendidosSheet.appendRow([v.name, v.qty, v.total.toStringAsFixed(2)]);
    }

    // -------------------------------------------------------------
    // HOJA: STOCK BAJO
    // -------------------------------------------------------------
    final stockSheet = excel['StockBajo'];
    stockSheet.appendRow(['Producto', 'Stock', 'Almacén']);

    for (final p in stats.productosLowStock) {
      stockSheet.appendRow([p.nombre, p.stock, p.almacenNombre]);
    }

    // -------------------------------------------------------------
    // DESCARGA
    // -------------------------------------------------------------
    final bytes = excel.encode();
    if (bytes == null) return;

    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'dashboard_export.xlsx',
    );
  }

  // =======================================================================
  // 🔥 EXPORTACIÓN PDF
  // =======================================================================

  static Future<void> exportAllPDF(DashboardStats stats) async {
    final pdf = pw.Document();

    final pedidosCompletos =
        await cargarPedidosCompletos(stats.pedidosFiltrados);

    final ventas = _agruparVentas(pedidosCompletos);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text("Reporte General del Dashboard",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 18),

          pw.Text("Pedidos (rango seleccionado)", style: _title),
          _pdfTablaPedidos(pedidosCompletos),
          pw.SizedBox(height: 20),

          pw.Text("Productos del Almacén", style: _title),
          _pdfTablaProductos(stats),
          pw.SizedBox(height: 20),

          pw.Text("Productos más vendidos (rango)", style: _title),
          _pdfTablaMasVendidos(ventas),
          pw.SizedBox(height: 20),

          pw.Text("Productos menos vendidos (rango)", style: _title),
          _pdfTablaMenosVendidos(stats, ventas),
          pw.SizedBox(height: 20),

          pw.Text("Productos vendidos (detalle)", style: _title),
          _pdfTablaVendidos(ventas),
          pw.SizedBox(height: 20),

          pw.Text("Productos con stock bajo", style: _title),
          _pdfTablaStockBajo(stats),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: "dashboard_export.pdf",
    );
  }

  // =======================================================================
  // 🔥 TABLAS PDF
  // =======================================================================

  static final _title =
      pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);

  static pw.Widget _pdfTablaPedidos(List<_PedidoCompleto> list) {
    return pw.Table.fromTextArray(
      headers: const [
        'Código',
        'Dirección',
        'Dep',
        'Estado',
        'Fecha',
        'Total',
        'Repartidor'
      ],
      data: list
          .map((p) => [
                p.codigo,
                p.direccion,
                p.departamento,
                p.estado,
                p.createdAt.toIso8601String(),
                p.total.toStringAsFixed(2),
                p.repartidor
              ])
          .toList(),
    );
  }

  static pw.Widget _pdfTablaProductos(DashboardStats stats) {
    return pw.Table.fromTextArray(
      headers: ['Producto', 'Stock', 'Unidad', 'Precio', 'Almacén'],
      data: stats.productosDelAlmacen
          .map((p) => [
                p.nombre,
                p.stock,
                p.unidad,
                p.precio.toStringAsFixed(2),
                p.almacenNombre
              ])
          .toList(),
    );
  }

  static pw.Widget _pdfTablaMasVendidos(_VentasAgg ventas) {
    return pw.Table.fromTextArray(
      headers: ['Producto', 'Cantidad', 'Ventas (Bs)'],
      data: ventas.masVendidos
          .map((v) => [v.name, v.qty, v.total.toStringAsFixed(2)])
          .toList(),
    );
  }

  static pw.Widget _pdfTablaMenosVendidos(
      DashboardStats stats, _VentasAgg ventas) {
    final menos = ventas.menosVendidos(stats.productosDelAlmacen);

    return pw.Table.fromTextArray(
      headers: ['Producto', 'Stock', 'Unidad', 'Precio'],
      data: menos
          .map(
              (p) => [p.nombre, p.stock, p.unidad, p.precio.toStringAsFixed(2)])
          .toList(),
    );
  }

  static pw.Widget _pdfTablaVendidos(_VentasAgg ventas) {
    return pw.Table.fromTextArray(
      headers: ['Producto', 'Cantidad', 'Ventas (Bs)'],
      data: ventas.listado
          .map((v) => [v.name, v.qty, v.total.toStringAsFixed(2)])
          .toList(),
    );
  }

  static pw.Widget _pdfTablaStockBajo(DashboardStats stats) {
    return pw.Table.fromTextArray(
      headers: ['Producto', 'Stock', 'Almacén'],
      data: stats.productosLowStock
          .map((p) => [p.nombre, p.stock, p.almacenNombre])
          .toList(),
    );
  }
}

// ===========================================================================
// 🔥 MODELOS INTERNOS PARA AGREGAR VENTAS
// ===========================================================================

class _ItemVenta {
  final String name;
  final num qty;
  final double price;

  _ItemVenta({
    required this.name,
    required this.qty,
    required this.price,
  });
}

class _PedidoCompleto {
  final String id;
  final String codigo;
  final String direccion;
  final String departamento;
  final String estado;
  final DateTime createdAt;
  final double total;
  final String repartidor;

  final List<_ItemVenta> items;

  _PedidoCompleto({
    required this.id,
    required this.codigo,
    required this.direccion,
    required this.departamento,
    required this.estado,
    required this.createdAt,
    required this.total,
    required this.repartidor,
    required this.items,
  });
}

class _VentaProducto {
  final String name;
  num qty = 0;
  double total = 0;

  _VentaProducto(this.name);
}

class _VentasAgg {
  final List<_VentaProducto> listado;
  final List<_VentaProducto> masVendidos;

  _VentasAgg({
    required this.listado,
    required this.masVendidos,
  });

  List<ProductoDetalleMini> menosVendidos(List<ProductoDetalleMini> all) {
    final vendidosNames = listado.map((v) => v.name).toSet();

    return all.where((p) => !vendidosNames.contains(p.nombre)).toList();
  }
}

_VentasAgg _agruparVentas(List<_PedidoCompleto> pedidos) {
  final Map<String, _VentaProducto> map = {};

  for (final p in pedidos) {
    for (final it in p.items) {
      map.putIfAbsent(it.name, () => _VentaProducto(it.name));
      map[it.name]!.qty += it.qty;
      map[it.name]!.total += it.qty * it.price;
    }
  }

  final list = map.values.toList()
    ..sort((a, b) => b.qty.compareTo(a.qty));

  return _VentasAgg(listado: list, masVendidos: list.take(10).toList());
}