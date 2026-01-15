import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';

class CountPill extends StatelessWidget {
  const CountPill({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: ink,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class HintPill extends StatelessWidget {
  const HintPill({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: ink.withValues(alpha: 0.55),
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.estado});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(estado);
    final label = _label(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Palette.ink.withValues(alpha: 0.9),
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
        ),
      ),
    );
  }

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

  Color _statusColor(String s) {
    switch (s) {
      case 'entregado':
        return Palette.statsSuccess;
      case 'cancelado':
        return Palette.statsDanger;
      case 'en camino':
        return Palette.statsWarning;
      case 'pendiente':
      default:
        return Palette.primary;
    }
  }
}

Widget miniPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Palette.ink.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Palette.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Palette.ink.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Color statusColor(String s) {
    switch (s) {
      case 'entregado':
        return Palette.statsSuccess;
      case 'cancelado':
        return Palette.statsDanger;
      case 'en camino':
        return Palette.statsWarning;
      case 'Aceptado':
        return Palette.statsSuccess;
      case 'pendiente':
      default:
        return Palette.primary;
  }
}

class LoadingFancy extends StatelessWidget {
  const LoadingFancy({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 34,
            width: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              color: ink.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.query, required this.estado});
  final String query;
  final String estado;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ink.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 44,
                color: ink.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 10),
              Text(
                'Sin resultados',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Estado: $estado${query.isEmpty ? '' : ' • "$query"'}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}