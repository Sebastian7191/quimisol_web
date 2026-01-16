
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';
import 'package:quimisol_web/features/pedidos/controllers/detalle_controller.dart';

import 'warn_box.dart';

class RepartidorPickerWidget extends StatelessWidget {
  const RepartidorPickerWidget({
    super.key,
    required this.departamento,
    required this.almacenId,
    required this.valueUid,
    required this.valueNombre,
    required this.onChanged,
    required this.controller,
  });

  final String departamento;
  final String almacenId;
  final String? valueUid;
  final String? valueNombre;
  final Function(String? uid, String? nombre)? onChanged;
  final PedidoDetalleController controller;

  @override
  Widget build(BuildContext context) {
    if (departamento.isEmpty && almacenId.isEmpty) {
      return WarnBox(text: 'Este pedido no tiene departamento ni almacenId.');
    }

    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: controller.fetchRepartidores(
        departamento: departamento,
        almacenId: almacenId,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _ghostField('Cargando repartidores…');
        }
        if (snap.hasError) {
          return WarnBox(text: 'Error: ${snap.error}');
        }

        final options = snap.data ?? [];
        if (options.isEmpty) {
          return WarnBox(text: 'No hay repartidores disponibles.');
        }

        final repartidoresMap = {
          for (final doc in options)
            doc.id:
                ((doc.data() as Map<String, dynamic>?)?['name'] ??
                        (doc.data() as Map<String, dynamic>?)?['nombre'] ??
                        'Repartidor')
                    .toString(),
        };

        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Palette.fieldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Palette.ink.withValues(alpha: 0.06)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: valueUid,
              isExpanded: true,
              hint: const Text('Seleccionar repartidor…'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('— Sin asignar —'),
                ),
                ...repartidoresMap.entries.map(
                  (e) => DropdownMenuItem<String?>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                ),
              ],
              onChanged: onChanged == null
                  ? null
                  : (uid) => onChanged!(uid, repartidoresMap[uid]),
            ),
          ),
        );
      },
    );
  }

  Widget _ghostField(String text) {
    return Container(
      alignment: Alignment.centerLeft,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Palette.fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.ink.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Palette.ink.withValues(alpha: 0.7),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}