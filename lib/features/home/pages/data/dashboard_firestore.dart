import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardFirestore {
  final FirebaseFirestore _db;
  DashboardFirestore(this._db);

  /// Stream de pedidos optimizado para Dashboard.
  ///
  /// ✅ Evita bugs por datos inconsistentes (estado/departamento a veces vienen
  /// en minúsculas o dentro de `ubicacion`), por eso NO filtramos aquí por
  /// estado/departamento. Esos filtros se aplican en memoria en la UI.
  ///
  /// ✅ Reduce carga: ordena por createdAt desc y limita resultados.
  Stream<QuerySnapshot<Map<String, dynamic>>> pedidosStream({
    DateTime? from,
    int limit = 1500,
  }) {
    Query<Map<String, dynamic>> q = _db.collection('pedidos');

    if (from != null) {
      // Para inequality se recomienda orderBy del mismo campo.
      q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
           .orderBy('createdAt', descending: true);
    } else {
      // "Todo" puede ser enorme, limitamos igualmente para que no reviente la UI.
      q = q.orderBy('createdAt', descending: true);
    }

    return q.limit(limit).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> productosStream({
    String? almacenId,
  }) {
    Query<Map<String, dynamic>> q = _db.collection('productos');
    if (almacenId != null) {
      q = q.where('almacenId', isEqualTo: almacenId);
    }
    return q.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> usuariosStream() =>
      _db.collection('usuarios').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> almacenesStream() =>
      _db.collection('almacenes').where('activo', isEqualTo: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> repartidoresStream({
    String? almacenId,
  }) {
    Query<Map<String, dynamic>> q = _db.collection('repartidores');
    if (almacenId != null) {
      q = q.where('almacenId', isEqualTo: almacenId);
    }
    return q.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> bannersStream() =>
      _db.collection('banners').snapshots();
}
