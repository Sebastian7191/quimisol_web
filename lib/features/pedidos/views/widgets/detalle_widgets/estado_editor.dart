import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';

class EstadoEditor extends StatelessWidget {
  const EstadoEditor({
    super.key,
    required this.estadoActual,
    required this.value,
    required this.onChanged,
  });

  final String estadoActual;
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    final options = <String>{
      estadoActual,
      if (estadoActual == 'pendiente') 'Aceptado',
    }.toList();
    //.toSet().toList();

    String label(String v) {
      switch (v) {
        case 'Aceptado':
          return 'Aceptado';
        case 'pendiente':
          return 'Pendiente';
        case 'en camino':
          return 'En camino';
        case 'entregado':
          return 'Entregado';
        case 'cancelado':
          return 'Cancelado';
        default:
          return v;
      }
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Palette.fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Palette.white,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ink.withValues(alpha: 0.55),
          ),
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
            fontSize: 12.8,
          ),
          onChanged: onChanged == null ? null : (v) => onChanged!(v ?? value),
          items: options
              .map(
                (e) =>
                    DropdownMenuItem<String>(value: e, child: Text(label(e))),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}