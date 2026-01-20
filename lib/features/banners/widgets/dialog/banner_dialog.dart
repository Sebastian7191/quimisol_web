// lib/features/banners/widgets/dialog/banner_dialog.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';

import 'package:quimisol_web/core/theme/palette.dart';
import 'package:quimisol_web/features/banners/controllers/banners_dialog_controller.dart';
import 'package:quimisol_web/features/banners/widgets/dialog/form_result.dart';

import 'package:quimisol_web/features/banners/widgets/dialog/product_autocomplete_field.dart';
import 'package:quimisol_web/features/banners/widgets/dialog/product_list_selector.dart';
import 'package:quimisol_web/features/banners/widgets/preview/banner_dialog_preview_panel.dart';

class BannerDialog extends StatefulWidget {
  final String title;

  final String? initialTitulo;
  final String? initialSubtitulo;
  final String? initialImagen;
  final String? initialEstado;
  final String? initialIdProducto;

  const BannerDialog({
    super.key,
    required this.title,
    this.initialTitulo,
    this.initialSubtitulo,
    this.initialImagen,
    this.initialEstado,
    this.initialIdProducto,
  });

  @override
  State<BannerDialog> createState() => _BannerDialogState();
}

class _BannerDialogState extends State<BannerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final BannersDialogController controller;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    controller = BannersDialogController(
      initialTitulo: widget.initialTitulo ?? '',
      initialSubtitulo: widget.initialSubtitulo ?? '',
      initialImagen: widget.initialImagen ?? '',
      initialEstado: (widget.initialEstado ?? 'ACTIVO').toUpperCase(),
      initialIdProducto: widget.initialIdProducto ?? '',
    );

    // cargar productos para el combo buscador
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.loadProducts();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    // pick bytes (web)
    final Uint8List? bytes = await ImagePickerWeb.getImageAsBytes();
    if (bytes == null) return;

    // intenta adivinar extensión simple (si no, jpg)
    final ext = 'jpg';

    try {
      await controller.uploadBannerBytes(bytes: bytes, fileExt: ext);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submit() {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    // ✅ mínimo: título, subtítulo y producto seleccionado
    if (!controller.validateBasic()) return;

    setState(() => _saving = true);

    Navigator.pop(
      context,
      BannerFormResult(
        titulo: controller.tituloCtrl.text,
        subtitulo: controller.subtituloCtrl.text,
        imagen: controller.finalImagenUrl, // ✅ auto: custom o imagen producto
        estado: controller.estado,
        idproducto: controller.idProductoCtrl.text, // ✅ id del producto elegido
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Palette.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth >= 920;

                  final form = _FormCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: controller.tituloCtrl,
                            decoration: InputDecoration(
                              labelText: 'Título (Ej: descuentos)',
                              filled: true,
                              fillColor: Palette.fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingresa un título';
                              }
                              if (v.trim().length < 2)
                                return 'Mínimo 2 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: controller.subtituloCtrl,
                            decoration: InputDecoration(
                              labelText: 'Subtítulo (Ej: 20%)',
                              filled: true,
                              fillColor: Palette.fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingresa un subtítulo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ✅ Combo buscador de producto (con imagen)
                          ProductListSelector(
                            products: controller.products,
                            selected: controller.selectedProduct,
                            enabled: !controller.loadingProducts,
                            onSelected: (p) =>
                                setState(() => controller.selectProduct(p)),
                            height: 300,
                          ),

                          const SizedBox(height: 12),

                          // ✅ Imagen: no URL; usa producto o sube
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Palette.fieldBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Palette.button.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LEFT: acciones
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Imagen del banner',
                                        style: TextStyle(
                                          color: Palette.ink.withValues(
                                            alpha: 0.85,
                                          ),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        controller.finalImagenUrl.trim().isEmpty
                                            ? 'Se usará la imagen del producto (si eliges uno) o puedes subir una.'
                                            : 'Imagen lista ✅ (producto o subida)',
                                        style: TextStyle(
                                          color: Palette.ink.withValues(
                                            alpha: 0.65,
                                          ),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: controller.uploadingImage
                                                ? null
                                                : _pickAndUploadImage,
                                            icon: const Icon(
                                              Icons.upload_rounded,
                                            ),
                                            label: Text(
                                              controller.uploadingImage
                                                  ? 'Subiendo...'
                                                  : 'Subir imagen',
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Palette.ink,
                                              side: BorderSide(
                                                color: Palette.button
                                                    .withValues(alpha: 0.55),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: controller.uploadingImage
                                                ? null
                                                : () => setState(
                                                    controller.clearCustomImage,
                                                  ),
                                            icon: const Icon(
                                              Icons.restore_rounded,
                                            ),
                                            label: const Text(
                                              'Usar imagen del producto',
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Palette.ink,
                                              side: BorderSide(
                                                color: Palette.button
                                                    .withValues(alpha: 0.35),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // RIGHT: preview de imagen
                                _DialogImagePreview(
                                  url: controller.previewUrl,
                                  bytes: controller.previewBytes,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: controller.estado,
                            items: const [
                              DropdownMenuItem(
                                value: 'ACTIVO',
                                child: Text('ACTIVO'),
                              ),
                              DropdownMenuItem(
                                value: 'INACTIVO',
                                child: Text('INACTIVO'),
                              ),
                            ],
                            onChanged: (v) => setState(
                              () => controller.setEstado(v ?? 'ACTIVO'),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Estado',
                              filled: true,
                              fillColor: Palette.fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  final preview = BannerDialogPreviewPanel(
                    controller: controller,
                  );

                  if (!isWide) {
                    return Column(
                      children: [form, const SizedBox(height: 14), preview],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: form),
                      const SizedBox(width: 14),
                      Expanded(flex: 5, child: preview),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Palette.ink,
                        side: BorderSide(
                          color: Palette.button.withValues(alpha: 0.55),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.button,
                        foregroundColor: Palette.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Guardar',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.button.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

class _DialogImagePreview extends StatelessWidget {
  const _DialogImagePreview({
    required this.url,
    required this.bytes,
  });

  final String url;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final hasBytes = bytes != null;
    final hasUrl = url.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 220,
        height: 140,
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Palette.button.withValues(alpha: 0.22)),
        ),
        child: hasBytes
            ? Image.memory(bytes!, fit: BoxFit.cover)
            : (hasUrl
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _NoImgBox(),
                  )
                : const _NoImgBox()),
      ),
    );
  }
}

class _NoImgBox extends StatelessWidget {
  const _NoImgBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.fieldBg,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 34,
          color: Palette.ink.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

