import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quimisol_web/features/productos/controllers/producto_dialog_controller.dart';

import 'package:quimisol_web/features/productos/data/almacen_option.dart';
import 'package:quimisol_web/features/productos/data/unidad_option.dart';
import 'package:quimisol_web/features/productos/views/widgets/dialogs/producto_dialog_discount_block.dart';
import 'package:quimisol_web/features/productos/views/widgets/dialogs/producto_dialog_image_card.dart';
import 'package:quimisol_web/features/productos/views/widgets/dialogs/producto_dialog_ui.dart';

class ProductoDialogForm extends StatelessWidget {
  const ProductoDialogForm({
    super.key,
    required this.formKey,
    required this.controller,
    required this.unidades,
    required this.almacenes,
  });

  final GlobalKey<FormState> formKey;
  final ProductoDialogController controller;
  final List<UnidadOption> unidades;
  final List<AlmacenOption> almacenes;

  Stream<QuerySnapshot<Map<String, dynamic>>> _categoriasStream() {
    return FirebaseFirestore.instance.collection('categorias').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Form(
          key: formKey,
          child: Column(
            children: [
              ProductoDialogUI.sectionTitle(
                title: 'Datos generales',
                subtitle: 'Almacén, categoría, tipo, código y nombre.',
                icon: Icons.badge_rounded,
              ),
              ProductoDialogUI.gap(12),

              ProductoDialogUI.card(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: controller.almacenId,
                      items: almacenes
                          .map((a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.label),
                              ))
                          .toList(),
                      onChanged:
                          controller.saving ? null : controller.setAlmacenId,
                      decoration: ProductoDialogUI.decor(
                        label: 'Almacén',
                        prefixIcon: const Icon(Icons.warehouse_rounded),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Selecciona un almacén'
                          : null,
                    ),

                    // ✅ CATEGORÍAS
                    ProductoDialogUI.gap(),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _categoriasStream(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Text(
                            'Error al cargar categorías: ${snap.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        if (snap.connectionState == ConnectionState.waiting) {
                          return DropdownButtonFormField<String?>(
                            initialValue: controller.categoriaId,
                            items: const [],
                            onChanged: null,
                            decoration: ProductoDialogUI.decor(
                              label: 'Categoría',
                              hint: 'Cargando...',
                              prefixIcon: const Icon(Icons.category_rounded),
                            ),
                          );
                        }

                        final docs = snap.data?.docs ?? [];
                        final categorias = docs
                            .map((d) {
                              final data = d.data();
                              return {
                                'id': d.id,
                                'nombre':
                                    (data['nombre'] ?? '').toString().trim(),
                              };
                            })
                            .where((c) =>
                                (c['nombre'] ?? '').toString().isNotEmpty)
                            .toList();

                        if (categorias.isEmpty) {
                          return DropdownButtonFormField<String?>(
                            initialValue: null,
                            items: const [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('— Sin categorías —'),
                              ),
                            ],
                            onChanged: null,
                            decoration: ProductoDialogUI.decor(
                              label: 'Categoría',
                              hint: 'Crea una categoría primero',
                              prefixIcon: const Icon(Icons.category_rounded),
                            ),
                          );
                        }

                        final existsSelected =
                            controller.categoriaId != null &&
                                categorias.any((c) =>
                                    c['id'] == controller.categoriaId);

                        final selectedId =
                            existsSelected ? controller.categoriaId : null;

                        return DropdownButtonFormField<String?>(
                          initialValue: selectedId,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('— Seleccionar —'),
                            ),
                            ...categorias.map(
                              (c) => DropdownMenuItem<String?>(
                                value: c['id'] as String,
                                child: Text(c['nombre'] as String),
                              ),
                            ),
                          ],
                          onChanged: controller.saving
                              ? null
                              : (id) {
                                  if (id == null) {
                                    // ✅ YA NO FALLA: setCategoria acepta null
                                    controller.setCategoria(null, null);
                                    return;
                                  }
                                  final cat = categorias
                                      .firstWhere((c) => c['id'] == id);
                                  controller.setCategoria(
                                    id,
                                    (cat['nombre'] ?? '').toString(),
                                  );
                                },
                          decoration: ProductoDialogUI.decor(
                            label: 'Categoría',
                            prefixIcon: const Icon(Icons.category_rounded),
                            hint: 'Selecciona una categoría',
                          ),
                        );
                      },
                    ),

                    ProductoDialogUI.gap(),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller.codigoCtrl,
                            enabled: !controller.saving,
                            decoration: ProductoDialogUI.decor(
                              label: 'Código',
                              hint: 'Opcional',
                              prefixIcon: const Icon(Icons.qr_code_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: controller.tipoItem,
                            items: const [
                              DropdownMenuItem(
                                value: 'PRODUCTO',
                                child: Text('PRODUCTO'),
                              ),
                              DropdownMenuItem(
                                value: 'INSUMO',
                                child: Text('INSUMO'),
                              ),
                            ],
                            onChanged: controller.saving
                                ? null
                                : (v) => controller
                                    .setTipoItem(v ?? controller.tipoItem),
                            decoration: ProductoDialogUI.decor(
                              label: 'Tipo',
                              prefixIcon: const Icon(Icons.category_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ProductoDialogUI.gap(),

                    TextFormField(
                      controller: controller.nombreCtrl,
                      enabled: !controller.saving,
                      decoration: ProductoDialogUI.decor(
                        label: 'Nombre',
                        prefixIcon: const Icon(Icons.inventory_2_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa un nombre';
                        }
                        if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              ProductoDialogUI.gap(14),

              ProductoDialogUI.sectionTitle(
                title: 'Inventario',
                subtitle: 'Unidad, stock y precio.',
                icon: Icons.inventory_rounded,
              ),
              ProductoDialogUI.gap(12),

              ProductoDialogUI.card(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: controller.unidadId,
                            items: unidades
                                .map((u) => DropdownMenuItem(
                                      value: u.id,
                                      child: Text(u.label),
                                    ))
                                .toList(),
                            onChanged:
                                controller.saving ? null : controller.setUnidadId,
                            decoration: ProductoDialogUI.decor(
                              label: 'Unidad',
                              prefixIcon: const Icon(Icons.straighten_rounded),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Selecciona una unidad'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: controller.stockCtrl,
                            enabled: !controller.saving,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: ProductoDialogUI.decor(
                              label: 'Stock',
                              prefixIcon: const Icon(Icons.numbers_rounded),
                              helper: 'Solo enteros (ej: 0, 5, 12).',
                            ),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null) return 'Solo enteros';
                              if (n < 0) return 'No puede ser negativo';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    ProductoDialogUI.gap(),

                    TextFormField(
                      controller: controller.precioCtrl,
                      enabled: !controller.saving,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*([.,]\d{0,2})?$'),
                        ),
                      ],
                      decoration: ProductoDialogUI.decor(
                        label: 'Precio (Bs)',
                        prefixIcon: const Icon(Icons.payments_rounded),
                        helper: 'Admite decimales (ej: 10.5 o 10,50).',
                      ),
                      validator: (v) {
                        final p = controller.parsePrecio(v ?? '');
                        if (p < 0) return 'No puede ser negativo';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              ProductoDialogUI.gap(14),

              ProductoDialogUI.sectionTitle(
                title: 'Descuento',
                subtitle: 'Opcional: configura una promo para este producto.',
                icon: Icons.local_offer_rounded,
              ),
              ProductoDialogUI.gap(12),
              ProductoDialogDiscountBlock(controller: controller),

              ProductoDialogUI.gap(14),

              ProductoDialogUI.sectionTitle(
                title: 'Descripción',
                subtitle: 'Opcional: útil para detallar el producto.',
                icon: Icons.subject_rounded,
              ),
              ProductoDialogUI.gap(12),

              ProductoDialogUI.card(
                child: TextFormField(
                  controller: controller.descCtrl,
                  enabled: !controller.saving,
                  minLines: 4,
                  maxLines: 6,
                  decoration: ProductoDialogUI.decor(
                    label: 'Descripción',
                    hint: 'Ej: características, uso, contenido...',
                    prefixIcon: const Icon(Icons.notes_rounded),
                  ),
                ),
              ),

              ProductoDialogUI.gap(14),

              ProductoDialogUI.sectionTitle(
                title: 'Imagen',
                subtitle: 'Opcional: puedes subir una foto para el catálogo.',
                icon: Icons.image_rounded,
              ),
              ProductoDialogUI.gap(12),
              ProductoDialogImageCard(controller: controller),

              ProductoDialogUI.gap(16),
            ],
          ),
        );
      },
    );
  }
}
