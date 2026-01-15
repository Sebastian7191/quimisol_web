import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoDetalleData {
  final String id;

  final String codigo;
  final String estado;

  final String clienteUid;
  final String clienteNombre;
  final String clienteEmail;

  final String direccion;
  final String departamento;
  final String almacenId;

  final DateTime createdAt;
  final DateTime? fechaEnvio;

  final double totalProductos;
  final double costoEnvio;
  double get totalFinal => totalProductos + costoEnvio;

  final String? repartidorUid;
  final String? repartidorNombre;

  final List<PedidoItemData> items;

  PedidoDetalleData({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.clienteUid,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.direccion,
    required this.departamento,
    required this.almacenId,
    required this.createdAt,
    required this.fechaEnvio,
    required this.totalProductos,
    required this.costoEnvio,
    required this.repartidorUid,
    required this.repartidorNombre,
    required this.items,
  });

  factory PedidoDetalleData.fromFirestore(
    String id,
    Map<String, dynamic> p, {
    required String clienteNombre,
    required String clienteEmail,
  }) {
    final ubic = (p['ubicacion'] is Map) ? Map<String, dynamic>.from(p['ubicacion']) : {};

    final itemsRaw = (p['items'] is List) ? p['items'] as List : [];

    return PedidoDetalleData(
      id: id,
      codigo: (p['codigo'] ?? '—').toString(),
      estado: (p['estado'] ?? 'pendiente').toString(),
      clienteUid: (p['uid'] ?? '').toString(),
      clienteNombre: clienteNombre,
      clienteEmail: clienteEmail,
      direccion: (p['direccion'] ?? ubic['direccion'] ?? '').toString(),
      departamento: (p['departamento'] ?? ubic['departamento'] ?? '').toString(),
      almacenId: (p['almacenId'] ??
              p['almacen_id'] ??
              p['almacenUid'] ??
              p['almacen_uid'] ??
              '')
          .toString(),
      createdAt: _tsToDate(p['createdAt']),
      fechaEnvio: _tsNullable(p['fecha_envio'] ?? p['fechaEnvio']),
      totalProductos: _asDouble(p['total']),
      costoEnvio: _asDouble(p['costo_envio']),
      repartidorUid: _nullable(p['repartidorUid']),
      repartidorNombre: _nullable(p['repartidorNombre']),
      items: itemsRaw
          .whereType<Map>()
          .map((e) => PedidoItemData.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/* ===================== ITEMS ===================== */

class PedidoItemData {
  final String nombre;
  final String imageUrl;
  final int cantidad;
  final double precio;

  double get subtotal => cantidad * precio;

  PedidoItemData({
    required this.nombre,
    required this.imageUrl,
    required this.cantidad,
    required this.precio,
  });

  factory PedidoItemData.fromMap(Map<String, dynamic> m) {
    return PedidoItemData(
      nombre: (m['name'] ?? '—').toString(),
      imageUrl: (m['imageUrl'] ?? '').toString(),
      cantidad: _asInt(m['qty'], fallback: 1),
      precio: _asDouble(m['price']),
    );
  }
}

/* ===================== HELPERS PRIVADOS ===================== */

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

DateTime _tsToDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return DateTime.now();
}

DateTime? _tsNullable(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return null;
}

String? _nullable(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}