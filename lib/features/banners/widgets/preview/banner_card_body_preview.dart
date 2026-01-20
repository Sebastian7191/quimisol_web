// lib/features/banners/widgets/preview/banner_card_body_preview.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';

class BannerCardBodyPreview extends StatelessWidget {
  const BannerCardBodyPreview({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.imageUrl,
    this.pickedBytes,
  });

  final String titulo;
  final String subtitulo;
  final String imageUrl;
  final Uint8List? pickedBytes;

  @override
  Widget build(BuildContext context) {
    final hasPicked = pickedBytes != null;
    final hasUrl = imageUrl.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Palette.button.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
          child: LayoutBuilder(
            builder: (context, c) {
              // ✅ igual a tu BannerCard (body)
              final imageW = (c.maxWidth * 0.34).clamp(130.0, 200.0);

              return Row(
                children: [
                  // LEFT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo.trim().isEmpty ? 'Banner' : titulo.trim(),
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
                          subtitulo.trim().isEmpty ? '-' : subtitulo.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Palette.ink.withValues(alpha: 0.62),
                          ),
                        ),
                        const Spacer(),
                        const _PrimaryButton(text: 'Ver más'),
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
                      child: hasPicked
                          ? Image.memory(pickedBytes!, fit: BoxFit.cover)
                          : (hasUrl
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (_, __, ___) => const _NoImage(),
                                )
                              : const _NoImage()),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _NoImage extends StatelessWidget {
  const _NoImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Palette.ink.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
