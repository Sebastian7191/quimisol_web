import 'package:cloud_firestore/cloud_firestore.dart';

import 'pedido_item.dart';

class PedidoDetalleData {
  final String id;
  final String codigo;
  final String estado;

  final String direccion;
  final String departamento;
  final String ubicacionNombre;

  final String uidCliente;

  final DateTime? fechaEnvio;
  final double costoEnvio;

  final String? repartidorUid;
  final String? repartidorNombre;

  final double totalProductos;
  final double totalFinal;

  final List<PedidoItemData> items;

  final DateTime? createdAt;

  PedidoDetalleData({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.direccion,
    required this.departamento,
    required this.ubicacionNombre,
    required this.uidCliente,
    required this.fechaEnvio,
    required this.costoEnvio,
    required this.repartidorUid,
    required this.repartidorNombre,
    required this.totalProductos,
    required this.totalFinal,
    required this.items,
    required this.createdAt,
  });

  factory PedidoDetalleData.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final itemsRaw = (data['items'] is List) ? data['items'] as List : [];

    final items = itemsRaw
        .whereType<Map>()
        .map((e) => PedidoItemData.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final totalProductos = items.fold<double>(0, (sumT, e) => sumT + e.subtotal);

    final costoEnvio = _asDouble(data['costo_envio']);

    return PedidoDetalleData(
      id: doc.id,
      codigo: (data['codigo'] ?? '—').toString(),
      estado: (data['estado'] ?? 'pendiente').toString(),

      direccion: (data['direccion'] ?? '').toString(),
      departamento:
          (data['departamento'] ?? data['ubicacion']?['departamento'] ?? '')
              .toString(),
      ubicacionNombre: (data['ubicacion']?['nombre'] ?? '').toString(),

      uidCliente: (data['uid'] ?? '').toString(),

      fechaEnvio: _tsToDate(data['fecha_envio']),
      costoEnvio: costoEnvio,

      repartidorUid: (data['repartidorUid'] ?? '').toString().trim().isEmpty
          ? null
          : data['repartidorUid'],
      repartidorNombre:
          (data['repartidorNombre'] ?? '').toString().trim().isEmpty
          ? null
          : data['repartidorNombre'],

      totalProductos: totalProductos,
      totalFinal: totalProductos + costoEnvio,

      items: items,
      createdAt: _tsToDate(data['createdAt']),
    );
  }
}

/* helpers */
double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

DateTime? _tsToDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return null;
}
