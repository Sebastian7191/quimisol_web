// lib/features/pedidos/controllers/detalle_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/detalle_data.dart';

class PedidoDetalleController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtiene los datos completos del pedido tipados
  Future<PedidoDetalleData> fetchPedido(String pedidoId) async {
    final doc = await _firestore.collection('pedidos').doc(pedidoId).get();
    return PedidoDetalleData.fromDoc(doc);
  }

  // Obtiene cliente info (nombre, email)
  Future<Map<String, String>> fetchClienteInfo(String clienteUid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(clienteUid).get();
      final data = doc.data() ?? {};
      return {
        'nombre': (data['name'] ?? data['nombre'] ?? 'Cliente').toString(),
        'email': (data['email'] ?? '').toString(),
      };
    } catch (_) {
      return {'nombre': 'Cliente', 'email': ''};
    }
  }

  // Obtiene repartidores permitidos (por departamento y/o almacenId)
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchRepartidores({
    String? departamento,
    String? almacenId,
  }) async {
    // Si el pedido tiene almacenId específico, busca solo en ese almacén
    if (almacenId != null && almacenId.trim().isNotEmpty) {
      final q = await _firestore
          .collection('almacenes')
          .doc(almacenId)
          .collection('repartidores')
          .get();
      return q.docs;
    }

    // Si no, busca almacenes del departamento
    if (departamento != null && departamento.trim().isNotEmpty) {
      final almacenesSnap = await _firestore
          .collection('almacenes')
          .where('departamento', isEqualTo: departamento)
          .get();

      final repartidores = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final almacenDoc in almacenesSnap.docs) {
        final reps = await almacenDoc.reference
            .collection('repartidores')
            .get();
        repartidores.addAll(reps.docs);
      }
      return repartidores;
    }

    return [];
  }

  // Guarda cambios al pedido
  Future<void> guardarCambios({
    required String pedidoId,
    required String nuevoEstado,
    DateTime? fechaEnvio,
    double? costoEnvio,
    String? repartidorUid,
    String? repartidorNombre,
  }) async {
    final data = <String, dynamic>{};

    data['estado'] = nuevoEstado;

    if (fechaEnvio != null) {
      data['fecha_envio'] = Timestamp.fromDate(fechaEnvio);
    }
    if (costoEnvio != null) {
      data['costo_envio'] = costoEnvio;
    }

    if (repartidorUid != null && repartidorUid.isNotEmpty) {
      data['repartidorUid'] = repartidorUid;
      if (repartidorNombre != null && repartidorNombre.isNotEmpty) {
        data['repartidorNombre'] = repartidorNombre;
      }
    }

    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('pedidos').doc(pedidoId).update(data);
  }
}
