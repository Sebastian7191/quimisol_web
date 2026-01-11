// lib/features/admin/productos/widgets/dialog/widgets/producto_dialog_discount_block.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quimisol_web/features/productos/controllers/producto_dialog_controller.dart';
import 'package:quimisol_web/features/productos/widgets/dialog/producto_dialog_ui.dart';



class ProductoDialogDiscountBlock extends StatelessWidget {
  const ProductoDialogDiscountBlock({super.key, required this.controller});

  final ProductoDialogController controller;

  @override
  Widget build(BuildContext context) {
    return ProductoDialogUI.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String?>(
            value: controller.agregarDescuento,
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('— Seleccionar —')),
              DropdownMenuItem<String?>(value: 'SI', child: Text('Sí, agregar descuento')),
              DropdownMenuItem<String?>(value: 'NO', child: Text('No')),
            ],
            onChanged: controller.saving ? null : controller.setAgregarDescuento,
            decoration: ProductoDialogUI.decor(
              label: '¿Agregar descuento?',
              hint: 'Seleccionar',
              prefixIcon: const Icon(Icons.local_offer_rounded),
            ),
          ),

          if (controller.descuentoEnabled) ...[
            ProductoDialogUI.gap(12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: controller.descuentoTipo,
                    items: const [
                      DropdownMenuItem(value: 'PORCENTAJE', child: Text('PORCENTAJE')),
                      DropdownMenuItem(value: 'MONTO', child: Text('MONTO')),
                    ],
                    onChanged: controller.saving ? null : (v) => controller.setDescuentoTipo(v ?? controller.descuentoTipo),
                    decoration: ProductoDialogUI.decor(
                      label: 'Tipo',
                      prefixIcon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller.descuentoCtrl,
                    enabled: !controller.saving,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d{0,2})?$')),
                    ],
                    decoration: ProductoDialogUI.decor(
                      label: controller.descuentoTipo == 'PORCENTAJE' ? 'Valor (%)' : 'Valor (Bs)',
                      prefixIcon: Icon(
                        controller.descuentoTipo == 'PORCENTAJE'
                            ? Icons.percent_rounded
                            : Icons.payments_rounded,
                      ),
                    ),
                    validator: (v) {
                      if (!controller.descuentoEnabled) return null;
                      final val = controller.parseDouble(v ?? '');
                      if (val <= 0) return 'Ingresa un valor > 0';
                      if (controller.descuentoTipo == 'PORCENTAJE' && val > 100) return 'Máximo 100%';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
