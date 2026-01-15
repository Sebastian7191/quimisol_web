import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';

class EstadoPill extends StatelessWidget {
  const EstadoPill({super.key, required this.estado});
  final String estado;

  String _label(String s) {
    switch (s) {
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      case 'en camino':
        return 'En camino';
      case 'Aceptado':
        return 'Aceptado';
      case 'pendiente':
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(estado);
    final label = _label(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(estado), size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.black.withValues(alpha: 0.12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'entregado':
        return Palette.statsSuccess;
      case 'cancelado':
        return Palette.statsDanger;
      case 'en camino':
        return Palette.statsWarning;
      case 'Aceptado':
        return Palette.secondary;
      case 'pendiente':
      default:
        return Palette.primary;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'entregado':
        return Icons.check_circle_rounded;
      case 'cancelado':
        return Icons.cancel_rounded;
      case 'en camino':
        return Icons.local_shipping_rounded;
      case 'Aceptado':
        return Icons.verified_rounded;
      case 'pendiente':
      default:
        return Icons.schedule_rounded;
    }
  }
}