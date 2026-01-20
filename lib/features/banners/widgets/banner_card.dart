import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';

class BannerCard extends StatelessWidget {
  final String titulo;
  final String subtitulo; // "20%"
  final String imagen; // url
  final String estado; // ACTIVO/INACTIVO

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BannerCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.imagen,
    required this.estado,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActivo = estado.toUpperCase() == 'ACTIVO';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Palette.button.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            // =================== BODY ===================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
                child: LayoutBuilder(
                  builder: (context, c) {
                    // ✅ MÁS PEQUEÑA
                    final imageW = (c.maxWidth * 0.34).clamp(130.0, 200.0);

                    return Row(
                      children: [
                        // LEFT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titulo.isEmpty ? 'Banner' : titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Palette.ink,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitulo.isEmpty ? '-' : subtitulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Palette.ink.withValues(alpha: 0.62),
                                ),
                              ),
                              const Spacer(),
                              _PrimaryButton(
                                text: 'Ver más',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // RIGHT IMAGE
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: imageW,
                            height: double.infinity,
                            child: imagen.trim().isEmpty
                                ? Container(
                                    color: Colors.black12,
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported_rounded,
                                        color: Palette.ink.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    imagen,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.black12,
                                      child: Center(
                                        child: Icon(
                                          Icons.broken_image_rounded,
                                          color: Palette.statsDanger
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // =================== FOOTER ===================
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Palette.fieldBg.withValues(alpha: 0.55),
                border: Border(
                  top: BorderSide(color: Palette.button.withValues(alpha: 0.16)),
                ),
              ),
              child: Row(
                children: [
                  _EstadoChip(isActivo: isActivo),
                  const Spacer(),
                  _IconAction(
                    tooltip: 'Editar',
                    icon: Icons.edit_rounded,
                    color: Palette.primary,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 10),
                  _IconAction(
                    tooltip: 'Eliminar',
                    icon: Icons.delete_outline_rounded,
                    color: Palette.statsDanger.withValues(alpha: 0.95),
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PrimaryButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Palette.primary.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Palette.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final bool isActivo;
  const _EstadoChip({required this.isActivo});

  @override
  Widget build(BuildContext context) {
    final bg = isActivo
        ? Palette.statsSuccess.withValues(alpha: 0.14)
        : Palette.statsDanger.withValues(alpha: 0.12);

    final border = isActivo
        ? Palette.statsSuccess.withValues(alpha: 0.30)
        : Palette.statsDanger.withValues(alpha: 0.26);

    final fg = isActivo ? Palette.statsSuccess : Palette.statsDanger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            isActivo ? 'ACTIVO' : 'INACTIVO',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Palette.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.button.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
