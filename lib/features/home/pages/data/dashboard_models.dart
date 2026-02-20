import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

String _normBasic(String s) {
  var v = s.trim().toLowerCase();
  v = v
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');
  v = v.replaceAll('_', ' ');
  v = v.replaceAll(RegExp(r'\s+'), ' ');
  return v;
}

String normalizeEstado(String s) {
  final e = _normBasic(s);
  if (e == 'en camino') return 'en camino';
  return e;
}

String canonicalDepartamento(String raw) {
  final n = _normBasic(raw);
  const map = {
    'cochabamba': 'Cochabamba',
    'la paz': 'La Paz',
    'santa cruz': 'Santa Cruz',
    'oruro': 'Oruro',
    'potosi': 'Potosí',
    'chuquisaca': 'Chuquisaca',
    'tarija': 'Tarija',
    'beni': 'Beni',
    'pando': 'Pando',
  };
  return map[n] ?? (raw.trim().isEmpty ? '' : raw.trim());
}

//
// ------------------------------------------------------
// MINI MODELOS PARA DETALLE DEL ALMACÉN
// ------------------------------------------------------
//

class ProductoDetalleMini {
  final String id;
  final String nombre;
  final int stock;
  final String unidad;
  final double precio;
  final String almacenNombre;

  ProductoDetalleMini({
    required this.id,
    required this.nombre,
    required this.stock,
    required this.unidad,
    required this.precio,
    required this.almacenNombre,
  });
}

class RepartidorDetalleMini {
  final String id;
  final String nombre;
  final String email;
  final String foto;
  final String almacenId;

  RepartidorDetalleMini({
    required this.id,
    required this.nombre,
    required this.email,
    required this.foto,
    required this.almacenId,
  });
}

class BannerDetalleMini {
  final String id;
  final String titulo;
  final String subtitulo;
  final String imagen;
  final String estado;

  BannerDetalleMini({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.imagen,
    required this.estado,
  });
}

//
// ─────────────────────────────────────────────────────────────
//   MODELO PRINCIPAL
// ─────────────────────────────────────────────────────────────
//

class DashboardStats {
  // pedidos
  final int pedidosTotal;
  final int pedidosPendientes;
  final int pedidosAceptados;
  final int pedidosEnCamino;
  final int pedidosEntregados;
  final int pedidosCancelados;

  final double ventasTotal;
  final double costoEnvioTotal;

  // productos
  final int productosTotal;
  final int productosStockBajo;
  final int productosStockCero;
  final Map<String, int> productosPorTipo;

  // usuarios
  final int usuariosTotal;

  // repartidores
  final int repartidoresTotal;

  // banners
  final int bannersTotal;
  final int bannersActivos;

  final List<PedidoMini> pedidosRecientes;

  /// 🔥 NUEVO: lista completa filtrada por rango
  final List<PedidoMini> pedidosFiltrados;

  final List<ProductoMini> productosLowStock;

  // charts
  final Map<DateTime, int> pedidosPorDia;
  final Map<String, int> pedidosPorDepartamento;
  final Map<String, int> pedidosPorEstado;

  // top productos
  final List<TopProductoVenta> topProductosVendidos;

  // 🟩 DETALLE DEL ALMACÉN
  final List<ProductoDetalleMini> productosDelAlmacen;
  final List<RepartidorDetalleMini> repartidoresDelAlmacen;
  final List<BannerDetalleMini> bannersDelAlmacen;

  DashboardStats({
    required this.pedidosTotal,
    required this.pedidosPendientes,
    required this.pedidosAceptados,
    required this.pedidosEnCamino,
    required this.pedidosEntregados,
    required this.pedidosCancelados,
    required this.ventasTotal,
    required this.costoEnvioTotal,
    required this.productosTotal,
    required this.productosStockBajo,
    required this.productosStockCero,
    required this.productosPorTipo,
    required this.usuariosTotal,
    required this.repartidoresTotal,
    required this.bannersTotal,
    required this.bannersActivos,
    required this.pedidosRecientes,
    required this.pedidosFiltrados, // 🔥 NUEVO
    required this.productosLowStock,
    required this.pedidosPorDia,
    required this.pedidosPorDepartamento,
    required this.pedidosPorEstado,
    required this.topProductosVendidos,
    required this.productosDelAlmacen,
    required this.repartidoresDelAlmacen,
    required this.bannersDelAlmacen,
  });

  static DashboardStats build({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> pedidos,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> productos,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> usuarios,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> repartidores,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> banners,
    required String? almacenId,
    DateTime? rangeStart,
    int recentLimit = 6,
    int topProductsLimit = 8,
  }) {
    //
    // --------------------------------------------------------------------
    // PROCESAR PEDIDOS
    // --------------------------------------------------------------------
    //
    int pend = 0, acept = 0, enc = 0, entr = 0, canc = 0;
    double ventas = 0, costoEnvio = 0;

    final recent = <PedidoMini>[];
    final porDia = <DateTime, int>{};
    final porDep = <String, int>{};
    final porEstado = <String, int>{};

    final topAgg = <String, _TopAgg>{};

    for (final d in pedidos) {
      final m = d.data();

      final estadoRaw = (m['estado'] ?? '').toString();
      final estado = normalizeEstado(estadoRaw);

      final depRaw = (m['departamento'] ??
              (m['ubicacion'] is Map ? m['ubicacion']['departamento'] : ''))
          .toString();
      final dep = canonicalDepartamento(depRaw);

      if (dep.isNotEmpty) porDep[dep] = (porDep[dep] ?? 0) + 1;

      porEstado[estado] = (porEstado[estado] ?? 0) + 1;

      DateTime created = DateTime.now();
      final raw = m['createdAt'];
      if (raw is Timestamp) created = raw.toDate();
      if (raw is DateTime) created = raw;

      final key = DateTime(created.year, created.month, created.day);
      porDia[key] = (porDia[key] ?? 0) + 1;

      final total = _numToDouble(m['total']);
      final envio = _numToDouble(m['costo_envio']);

      ventas += total;
      costoEnvio += envio;

      if (estado == 'pendiente') pend++;
      else if (estado == 'aceptado') acept++;
      else if (estado == 'en camino') enc++;
      else if (estado == 'entregado') entr++;
      else if (estado == 'cancelado') canc++;

      final direccion = (m['direccion'] ??
              (m['ubicacion'] is Map ? m['ubicacion']['direccion'] : ''))
          .toString();

      recent.add(PedidoMini(
        id: d.id,
        codigo: (m['codigo'] ?? '').toString(),
        direccion: direccion,
        departamento: dep,
        estado: estadoRaw,
        createdAt: created,
        total: total,
        repartidorNombre: (m['repartidorNombre'] ?? '').toString(),
      ));

      final items = m['items'];
      if (items is List) {
        for (final it in items) {
          if (it is! Map) continue;

          final productId = (it['productId'] ?? '').toString();
          final name = (it['name'] ?? '').toString();
          final keyItem = productId.isNotEmpty ? productId : name;

          if (keyItem.isEmpty) continue;

          final qty = _numToInt(it['qty'] ?? 0);
          final price = _numToDouble(it['price'] ?? 0);

          final agg =
              topAgg.putIfAbsent(keyItem, () => _TopAgg(productId: productId, nombre: name));

          agg.qty += qty;
          agg.ventas += qty * price;
        }
      }
    }

    recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recentOut = recent.take(recentLimit).toList();

    /// 🔥 lista completa filtrada
    final filtradosOut = recent;

    final topList = topAgg.values.toList()..sort((a, b) => b.qty.compareTo(a.qty));
    final topOut = topList.take(topProductsLimit).map((a) {
      return TopProductoVenta(
        productId: a.productId,
        nombre: a.nombre,
        qty: a.qty,
        ventas: a.ventas,
      );
    }).toList();

    //
    // --------------------------------------------------------------------
    // PROCESAR PRODUCTOS
    // --------------------------------------------------------------------
    //
    final lowStock = <ProductoMini>[];
    final porTipo = <String, int>{};

    for (final d in productos) {
      final m = d.data();

      final nombre = (m['nombre'] ?? '').toString();
      final tipo = (m['tipoItem'] ?? 'Sin tipo').toString();

      porTipo[tipo] = (porTipo[tipo] ?? 0) + 1;

      final stock = _numToInt(m['stock']);

      if (stock <= 5) {
        lowStock.add(ProductoMini(
          id: d.id,
          nombre: nombre,
          stock: stock,
          almacenNombre: (m['almacenNombre'] ?? '').toString(),
        ));
      }
    }

    lowStock.sort((a, b) => a.stock.compareTo(b.stock));

    //
    // --------------------------------------------------------------------
    // DETALLES DEL ALMACÉN
    // --------------------------------------------------------------------
    //

    final productosDelAlmacen = productos.map((d) {
      final m = d.data();
      return ProductoDetalleMini(
        id: d.id,
        nombre: (m['nombre'] ?? '').toString(),
        stock: _numToInt(m['stock']),
        unidad: (m['unidadNombre'] ?? '').toString(),
        precio: _numToDouble(m['precio']),
        almacenNombre: (m['almacenNombre'] ?? '').toString(),
      );
    }).toList();

    final repartidoresDelAlmacen = repartidores.map((d) {
      final m = d.data();
      return RepartidorDetalleMini(
        id: d.id,
        nombre: (m['name'] ?? '').toString(),
        email: (m['email'] ?? '').toString(),
        foto: (m['photo'] ?? '').toString(),
        almacenId: (m['almacenId'] ?? '').toString(),
      );
    }).toList();

    final bannersDelAlmacen = banners.map((d) {
      final m = d.data();
      return BannerDetalleMini(
        id: d.id,
        titulo: (m['titulo'] ?? '').toString(),
        subtitulo: (m['subtitulo'] ?? '').toString(),
        imagen: (m['imagen'] ?? '').toString(),
        estado: (m['estado'] ?? '').toString(),
      );
    }).toList();

    return DashboardStats(
      pedidosTotal: pedidos.length,
      pedidosPendientes: pend,
      pedidosAceptados: acept,
      pedidosEnCamino: enc,
      pedidosEntregados: entr,
      pedidosCancelados: canc,
      ventasTotal: ventas,
      costoEnvioTotal: costoEnvio,
      productosTotal: productos.length,
      productosStockBajo: lowStock.length,
      productosStockCero: lowStock.where((p) => p.stock <= 0).length,
      productosPorTipo: porTipo,
      usuariosTotal: usuarios.length,
      repartidoresTotal: repartidores.length,
      bannersTotal: banners.length,
      bannersActivos: banners
          .where((b) => (b.data()['estado'] ?? '').toString().toUpperCase() == 'ACTIVO')
          .length,
      pedidosRecientes: recentOut,
      pedidosFiltrados: filtradosOut, // 🔥 NUEVO
      productosLowStock: lowStock.take(8).toList(),
      pedidosPorDia: porDia,
      pedidosPorDepartamento: porDep,
      pedidosPorEstado: porEstado,
      topProductosVendidos: topOut,
      productosDelAlmacen: productosDelAlmacen,
      repartidoresDelAlmacen: repartidoresDelAlmacen,
      bannersDelAlmacen: bannersDelAlmacen,
    );
  }

  static double _numToDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _numToInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }
}

//
// ------------------------------------------------------
// Mini modelos ya existentes
// ------------------------------------------------------
//

class PedidoMini {
  final String id;
  final String codigo;
  final String direccion;
  final String departamento;
  final String estado;
  final DateTime createdAt;
  final double total;
  final String repartidorNombre;

  PedidoMini({
    required this.id,
    required this.codigo,
    required this.direccion,
    required this.departamento,
    required this.estado,
    required this.createdAt,
    required this.total,
    required this.repartidorNombre,
  });
}

class ProductoMini {
  final String id;
  final String nombre;
  final int stock;
  final String almacenNombre;

  ProductoMini({
    required this.id,
    required this.nombre,
    required this.stock,
    required this.almacenNombre,
  });
}

class TopProductoVenta {
  final String productId;
  final String nombre;
  final int qty;
  final double ventas;

  TopProductoVenta({
    required this.productId,
    required this.nombre,
    required this.qty,
    required this.ventas,
  });
}

class _TopAgg {
  final String productId;
  final String nombre;
  int qty = 0;
  double ventas = 0;

  _TopAgg({required this.productId, required this.nombre});
}

List<DateTime> buildDayAxis(DateTime start, int days) {
  return List.generate(days, (i) {
    final d = start.add(Duration(days: i));
    return DateTime(d.year, d.month, d.day);
  });
}

int maxMapValue(Map<String, int> m) =>
    m.isEmpty ? 1 : m.values.fold(1, (a, b) => math.max(a, b));