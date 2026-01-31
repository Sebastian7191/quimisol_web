import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';
import '../../controllers/dashboard_controller.dart';

class DashboardFilters extends StatefulWidget {
  const DashboardFilters({
    super.key,
    required this.controller,
    required this.almacenes,
  });

  final DashboardController controller;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> almacenes;

  @override
  State<DashboardFilters> createState() => _DashboardFiltersState();
}

class _DashboardFiltersState extends State<DashboardFilters> {
  @override
  void didUpdateWidget(covariant DashboardFilters oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Evita crash: si el almacenId seleccionado ya no existe en items
    // (por carga lenta / activo=false / etc.), lo limpiamos.
    final id = widget.controller.almacenId;
    if (id != null && !widget.almacenes.any((d) => d.id == id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.controller.setAlmacen(null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAlm = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(value: null, child: Text('Todos los almacenes')),
      ...widget.almacenes.map((d) {
        final m = d.data();
        return DropdownMenuItem<String?>(
          value: d.id,
          child: Text((m['nombre'] ?? d.id).toString()),
        );
      }),
    ];

    final estados = const <String?>[
      null,
      'pendiente',
      'aceptado',
      'en camino',
      'entregado',
      'cancelado',
    ];

    final departamentos = const <String?>[
      null,
      'Cochabamba',
      'La Paz',
      'Santa Cruz',
      'Oruro',
      'Potosí',
      'Chuquisaca',
      'Tarija',
      'Beni',
      'Pando',
    ];

    final almId = widget.controller.almacenId;
    final safeAlmValue =
        (almId != null && widget.almacenes.any((d) => d.id == almId)) ? almId : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chipRange(context),
          _drop(
            label: 'Estado',
            value: widget.controller.estado,
            items: estados.map((e) {
              return DropdownMenuItem<String?>(
                value: e,
                child: Text(e == null ? 'Todos los estados' : e),
              );
            }).toList(),
            onChanged: (v) => widget.controller.setEstado(v),
          ),
          _drop(
            label: 'Departamento',
            value: widget.controller.departamento,
            items: departamentos.map((d) {
              return DropdownMenuItem<String?>(
                value: d,
                child: Text(d ?? 'Todos los departamentos'),
              );
            }).toList(),
            onChanged: (v) => widget.controller.setDepartamento(v),
          ),
          _drop(
            label: 'Almacén (productos/repartidores)',
            value: safeAlmValue,
            items: itemsAlm,
            onChanged: (v) => widget.controller.setAlmacen(v),
          ),
          TextButton.icon(
            onPressed: widget.controller.clear,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Widget _chipRange(BuildContext context) {
    Widget chip(String t, DashboardRange r) {
      final sel = widget.controller.range == r;
      return InkWell(
        onTap: () => widget.controller.setRange(r),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: sel
                ? Palette.primary.withValues(alpha: 0.14)
                : Palette.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: sel
                  ? Palette.primary.withValues(alpha: 0.35)
                  : Palette.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            t,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: sel ? Palette.primary : Palette.ink.withValues(alpha: 0.75),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      children: [
        chip('Hoy', DashboardRange.today),
        chip('7 días', DashboardRange.last7),
        chip('30 días', DashboardRange.last30),
        chip('Todo', DashboardRange.all),
      ],
    );
  }

  Widget _drop({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 260,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Palette.card.withValues(alpha: 0.55),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: value,
            isExpanded: true,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
