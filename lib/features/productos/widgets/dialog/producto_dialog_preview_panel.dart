import 'package:flutter/material.dart';

import 'package:quimisol_web/core/theme/palette.dart';
import 'package:quimisol_web/features/productos/controllers/producto_dialog_controller.dart';
import 'package:quimisol_web/features/productos/widgets/dialog/producto_dialog_ui.dart';
import 'package:quimisol_web/features/productos/widgets/producto_card_preview.dart';

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
                  color: Palette.button.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.button.withOpacity(0.25)),
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
              final hasDiscount = controller.descuentoEnabled && finalPrice < base;

              // Texto descuento (se mostrará DEBAJO del precio en la card)
              String? discountText;
              if (hasDiscount) {
                final val = controller.parseDouble(controller.descuentoCtrl.text);
                if (controller.descuentoTipo == 'PORCENTAJE') {
                  final pct = val.clamp(0, 100);
                  discountText =
                      'DESCUENTO -${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 2)}%';
                } else {
                  discountText = 'DESCUENTO -Bs ${val.toStringAsFixed(2)}';
                }
              }

              // ✅ Tamaños más chicos (para que NO desborde)
              const double phoneWidth = 260; // 👈 más chico
              const double phoneInnerScale = 0.92;

              return Center(
                child: SizedBox(
                  width: phoneWidth,
                  child: PhonePreviewFrame(
                    title: 'Vista previa móvil',
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final contentW = c.maxWidth * phoneInnerScale;

                        // Card tamaño “grid” real
                        final double cardW = (contentW * 0.92).clamp(185.0, 220.0);

                        return ScrollConfiguration(
                          behavior: const _NoScrollbarScrollBehavior(),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ✅ Top bar (sin buscador)
                                const _HomeTopPill(),

                                const SizedBox(height: 12),

                                // ✅ Banner (como tu foto)
                                const _HomePromoBanner(),

                                const SizedBox(height: 14),

                                // ✅ Card justo debajo del banner (posición roja)
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: cardW),
                                    child: ProductoCardPreview(
                                      name: name,
                                      stock: controller.parseStock(controller.stockCtrl.text),
                                      priceFinal: hasDiscount ? finalPrice : base,
                                      priceBase: hasDiscount ? base : null,
                                      discountBadgeText: discountText, // ahora se dibuja abajo del precio
                                      imageUrl: controller.existingImageUrl,
                                      pickedBytes: controller.pickedBytes,
                                      rating: 0.0,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),
                              ],
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
}

// ---------------------------
// Widgets del “home” preview
// ---------------------------

class _HomeTopPill extends StatelessWidget {
  const _HomeTopPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Palette.card.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.button.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.place_rounded, size: 18, color: Palette.ink.withOpacity(0.70)),
          const SizedBox(width: 6),
          const Text(
            'Todos',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Palette.ink,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: Palette.ink.withOpacity(0.65)),

          const Spacer(),

          _circleIcon(Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          _circleIcon(Icons.shopping_cart_outlined),
          const SizedBox(width: 10),

          // Avatar “S”
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFE74C3C),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Palette.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.button.withOpacity(0.12)),
      ),
      child: Icon(icon, size: 18, color: Palette.ink.withOpacity(0.70)),
    );
  }
}

class _HomePromoBanner extends StatelessWidget {
  const _HomePromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Collection',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Palette.ink,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Discount 50% for\nthe first transaction',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Palette.ink.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E57C2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    child: const Text('Shop Now'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // “imagen” derecha (placeholder)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 110,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Palette.button.withOpacity(0.18),
                    Palette.card.withOpacity(0.95),
                  ],
                ),
              ),
              child: Icon(
                Icons.chair_rounded,
                color: Palette.ink.withOpacity(0.25),
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ quita glow/scrollbar del preview
class _NoScrollbarScrollBehavior extends ScrollBehavior {
  const _NoScrollbarScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
