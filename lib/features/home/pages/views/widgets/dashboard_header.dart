import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.width,
    required this.onExportExcel,
    required this.onExportPdf,
  });

  final double width;

  // 🔥 CALLBACKS DE EXPORTACIÓN
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final compact = width < 700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Palette.primary.withOpacity(0.95),
            Palette.secondary.withOpacity(0.90),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono principal
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Palette.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Palette.white.withOpacity(0.35),
              ),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Palette.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          // Títulos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    color: Palette.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pedidos, productos, usuarios, repartidores y banners',
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    color: Palette.white.withOpacity(0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (!compact) const SizedBox(width: 16),

          // 🔥 EXPORTAR DATOS + BOTONES
          if (!compact)
            Row(
              children: [
                // 🔹 Texto "Exportar datos"
                Text(
                  "Exportar datos:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),

                const SizedBox(width: 12),

                // Botón Excel
                ElevatedButton.icon(
                  onPressed: onExportExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Palette.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.table_chart_rounded, size: 18),
                  label: const Text('Excel'),
                ),

                const SizedBox(width: 8),

                // Botón PDF
                ElevatedButton.icon(
                  onPressed: onExportPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.white.withOpacity(0.85),
                    foregroundColor: Palette.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('PDF'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}