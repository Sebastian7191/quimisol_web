import 'package:flutter/material.dart';

import 'package:quimisol_web/core/theme/palette.dart';
import 'package:quimisol_web/features/productos/controllers/producto_dialog_controller.dart';
import 'package:quimisol_web/features/productos/views/widgets/dialogs/producto_dialog_ui.dart';
import 'package:quimisol_web/features/productos/views/widgets/producto_card_preview.dart';

// ✅ Banner reusable (usa datos del producto)
import 'package:quimisol_web/features/productos/views/widgets/dialogs/promo_banner_preview.dart';

class ProductoDialogPreviewPanel extends StatelessWidget {
  const ProductoDialogPreviewPanel({super.key, required this.controller});

  final ProductoDialogController controller;

  @override
  Widget build(BuildContext context) {
    return ProductoDialogUI.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header del panel
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Palette.button.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.button.withValues(alpha: 0.25)),
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

          // ✅ SOLO refresca el preview
          ValueListenableBuilder<int>(
            valueListenable: controller.previewTick,
            builder: (_, __, ___) {
              final name = controller.nombreCtrl.text.trim().isEmpty
                  ? 'Producto'
                  : controller.nombreCtrl.text.trim();

              final base = controller.precioBaseNow();
              final finalPrice = controller.precioFinalPreview();
              final hasDiscount =
                  controller.descuentoEnabled && finalPrice < base;

              // Texto descuento (se mostrará DEBAJO del precio en la card)
              String? discountText;
              if (hasDiscount) {
                final val =
                    controller.parseDouble(controller.descuentoCtrl.text);
                if (controller.descuentoTipo == 'PORCENTAJE') {
                  final pct = val.clamp(0, 100);
                  discountText =
                      'DESCUENTO -${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 2)}%';
                } else {
                  discountText = 'DESCUENTO -Bs ${val.toStringAsFixed(2)}';
                }
              }

              // ✅ Un poco más ancho para que el banner no corte texto
              const double phoneWidth = 292;
              const double phoneInnerScale = 0.98;

              return Center(
                child: SizedBox(
                  width: phoneWidth,
                  child: PhonePreviewFrame(
                    title: 'Vista previa móvil',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final contentW =
                            constraints.maxWidth * phoneInnerScale;

                        // Card tamaño “grid” real
                        final double cardW =
                            (contentW * 0.92).clamp(195.0, 240.0);

                        return ColoredBox(
                          color: Palette.white,
                          child: ScrollConfiguration(
                            behavior: const _NoScrollbarScrollBehavior(),
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.only(top: 10),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: IntrinsicHeight(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // ✅ Promo banner (solo si activado)
                                      if (controller.promoBannerEnabled)
                                        PromoBannerPreview(
                                          productTitle: name,
                                          discountSubtitle: _buildDiscountSubtitle(
                                            controller,
                                            hasDiscount: hasDiscount,
                                          ),
                                          imageBytes: controller.pickedBytes,
                                          imageUrl: controller.existingImageUrl,
                                          buttonText: 'Ver más',
                                        ),

                                      // si está apagado no deja hueco feo
                                      if (!controller.promoBannerEnabled)
                                        const SizedBox(height: 2),

                                      const SizedBox(height: 14),

                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: ConstrainedBox(
                                          constraints:
                                              BoxConstraints(maxWidth: cardW),
                                          child: ProductoCardPreview(
                                            name: name,
                                            stock: controller.parseStock(
                                              controller.stockCtrl.text,
                                            ),
                                            priceFinal:
                                                hasDiscount ? finalPrice : base,
                                            priceBase:
                                                hasDiscount ? base : null,
                                            discountBadgeText: discountText,
                                            imageUrl:
                                                controller.existingImageUrl,
                                            pickedBytes: controller.pickedBytes,
                                            rating: 0.0,
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
              );
            },
          ),
        ],
      ),
    );
  }

  String _buildDiscountSubtitle(
    ProductoDialogController controller, {
    required bool hasDiscount,
  }) {
    if (!controller.descuentoEnabled || !hasDiscount) {
      return '¡No te lo pierdas!';
    }

    final val = controller.parseDouble(controller.descuentoCtrl.text);
    if (val <= 0) return '¡No te lo pierdas!';

    if (controller.descuentoTipo == 'PORCENTAJE') {
      final pct = val.clamp(0, 100);
      final pctStr = pct.toStringAsFixed(pct % 1 == 0 ? 0 : 2);
      return 'Descuento ($pctStr%) ¡No te lo pierdas!';
    } else {
      final bsStr = val.toStringAsFixed(2);
      return 'Descuento (Bs $bsStr) ¡No te lo pierdas!';
    }
  }
}

// ✅ quita glow/scrollbar del preview
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
