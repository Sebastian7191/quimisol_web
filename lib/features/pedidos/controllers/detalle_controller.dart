// lib/features/admin/pedidos/controllers/pedido_detalle_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/detalle_data.dart';

class PedidoDetalleController {
  final _fire = FirebaseFirestore.instance;

  /* ================= FETCH ================= */

  Future<PedidoDetalleData> fetchPedido(String pedidoId) async {
    final pedidoSnap =
        await _fire.collection('pedidos').doc(pedidoId).get();

    if (!pedidoSnap.exists || pedidoSnap.data() == null) {
      throw Exception('Pedido no encontrado');
    }

    final pedido = pedidoSnap.data()!;

    // Cliente
    final uid = (pedido['uid'] ?? '').toString();
    String clienteNombre = 'Cliente';
    String clienteEmail = '—';

    if (uid.isNotEmpty) {
      final userSnap = await _fire.collection('usuarios').doc(uid).get();
      final u = userSnap.data();
      if (u != null) {
        clienteNombre = (u['name'] ?? u['nombre'] ?? 'Cliente').toString();
        clienteEmail = (u['email'] ?? '—').toString();
      }
    }

    return PedidoDetalleData.fromFirestore(
      pedidoSnap.id,
      pedido,
      clienteNombre: clienteNombre,
      clienteEmail: clienteEmail,
    );
  }

  /* ================= REPARTIDORES ================= */

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchRepartidores({
    required String departamento,
    required String almacenId,
  }) async {
    List<String> almacenesIds = [];

    if (almacenId.isNotEmpty) {
      almacenesIds = [almacenId];
    } else if (departamento.isNotEmpty) {
      final q = await _fire
          .collection('almacenes')
          .where('departamento', isEqualTo: departamento)
          .where('activo', isEqualTo: true)
          .limit(10)
          .get();

      almacenesIds = q.docs.map((d) => d.id).toList();
    }

    if (almacenesIds.isEmpty) return [];

    final query = almacenesIds.length == 1
        ? _fire
            .collection('repartidores')
            .where('almacenId', isEqualTo: almacenesIds.first)
        : _fire
            .collection('repartidores')
            .where('almacenId', whereIn: almacenesIds);

    final snap = await query.get();
    return snap.docs;
  }

  /* ================= SAVE ================= */

  Future<void> guardarCambios({
    required PedidoDetalleData data,
    required String nuevoEstado,
    required DateTime? fechaEnvio,
    required double costoEnvio,
    required String? repartidorUid,
  }) async {
    final ref = _fire.collection('pedidos').doc(data.id);

    final updates = <String, dynamic>{};

    if (data.estado == 'pendiente' && nuevoEstado == 'Aceptado') {
      updates['estado'] = 'Aceptado';
    }

    updates['fecha_envio'] =
        fechaEnvio == null ? null : Timestamp.fromDate(fechaEnvio);

    updates['costo_envio'] = costoEnvio;

    if (repartidorUid != null && repartidorUid.isNotEmpty) {
      updates['repartidorUid'] = repartidorUid;

      final repSnap =
          await _fire.collection('repartidores').doc(repartidorUid).get();
      final rep = repSnap.data() ?? {};
      updates['repartidorNombre'] =
          (rep['name'] ?? rep['nombre'] ?? 'Repartidor').toString();
    } else {
      updates['repartidorUid'] = FieldValue.delete();
      updates['repartidorNombre'] = FieldValue.delete();
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();

    await ref.update(updates);
  }
}