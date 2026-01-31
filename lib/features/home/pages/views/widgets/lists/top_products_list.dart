import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';
import '../../../data/dashboard_models.dart';

class TopProductsList extends StatelessWidget {
  const TopProductsList({super.key, required this.items});
  final List<TopProductoVenta> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'Aún no hay items suficientes en los pedidos para calcular top productos.',
        style: TextStyle(
          color: Palette.ink.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      children: items.asMap().entries.map((e) {
        final i = e.key + 1;
        final p = e.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Palette.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Palette.primary.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Palette.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.primary.withValues(alpha: 0.22)),
                ),
                child: Text(
                  '$i',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Palette.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.productId.isEmpty ? 'sin id' : p.productId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Palette.ink.withValues(alpha: 0.60),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'x${p.qty}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.ventas.toStringAsFixed(0)} Bs',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: Palette.ink.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
