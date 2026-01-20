// lib/features/banners/widgets/preview/banner_dialog_preview_panel.dart
import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';
import 'package:quimisol_web/features/banners/controllers/banners_dialog_controller.dart';

import 'banner_phone_preview_frame.dart';
import 'banner_card_body_preview.dart';

class BannerDialogPreviewPanel extends StatelessWidget {
  const BannerDialogPreviewPanel({super.key, required this.controller});

  final BannersDialogController controller;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(
                  color: Palette.button.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Palette.button.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.phone_iphone_rounded,
                  color: Palette.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Vista previa',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Palette.ink,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ValueListenableBuilder<int>(
            valueListenable: controller.previewTick,
            builder: (_, __, ___) {
              final t = controller.tituloCtrl.text.trim();
              final s = controller.subtituloCtrl.text.trim();

              final url = controller.previewUrl; // custom subida o imagen del producto
              final bytes = controller.previewBytes;

              // ✅ (1) Esto controla el "tamaño" del teléfono
              //    Más chico => más espacio a los lados
              const double phoneWidth = 280;

              return Center(
                // ✅ (2) Esto crea MÁS ESPACIO a los costados del teléfono
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: SizedBox(
                    width: phoneWidth,
                    child: BannerPhonePreviewFrame(
                      title: 'Vista previa móvil',
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // ancho máximo de la card dentro del teléfono
                          final cardW = (constraints.maxWidth * 0.98).clamp(240.0, 280.0);

                          return ColoredBox(
                            color: Palette.white,
                            child: ScrollConfiguration(
                              behavior: const _NoScrollbarScrollBehavior(),
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                padding: const EdgeInsets.only(top: 10),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                  child: IntrinsicHeight(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Align(
                                          alignment: Alignment.topCenter,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(maxWidth: cardW),
                                            child: SizedBox(
                                              height: 130,
                                              child: BannerCardBodyPreview(
                                                titulo: t.isEmpty ? 'Banner' : t,
                                                subtitulo: s.isEmpty ? '-' : s,
                                                imageUrl: url,
                                                pickedBytes: bytes,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final Widget child;
  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.button.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NoScrollbarScrollBehavior extends ScrollBehavior {
  const _NoScrollbarScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
