// lib/features/banners/pages/banners.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quimisol_web/core/theme/palette.dart';
import 'package:quimisol_web/features/banners/widgets/dialog/banner_dialog.dart';
import 'package:quimisol_web/features/banners/widgets/dialog/form_result.dart';
import '../../../shared/dialogs/delete_dialog.dart';

import '../controllers/banners_controller.dart';
import '../widgets/banner_empty_box.dart';
import '../widgets/banner_error_box.dart';
import '../widgets/banner_loading_grid.dart';
import '../widgets/banner_card.dart';

class BannersPage extends StatefulWidget {
  const BannersPage({super.key});

  @override
  State<BannersPage> createState() => _BannersPageState();
}

class _BannersPageState extends State<BannersPage> {
  final controller = BannersController();

  @override
  void initState() {
    super.initState();
    controller.searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _bannersStream() =>
      controller.bannersStream();

  Future<BannerFormResult?> _showBannerDialog(Widget dialog) {
    FocusManager.instance.primaryFocus?.unfocus();

    return showDialog<BannerFormResult>(
      context: context,
      useRootNavigator: true, // ✅ CLAVE en Modular / navigators anidados
      barrierDismissible: false,
      builder: (_) => dialog,
    );
  }

  Future<void> _openAddDialog() async {
    final res = await _showBannerDialog(
      const BannerDialog(title: 'Agregar banner'),
    );

    if (res == null) return;

    try {
      await controller.crearBanner(
        titulo: res.titulo,
        subtitulo: res.subtitulo,
        imagen: res.imagen,
        estado: res.estado,
        idproducto: res.idproducto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner agregado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEditDialog({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    // ✅ IMPORTANTE:
    // Quité initialImagen/initialEstado/initialIdProducto porque tu BannerDialog
    // no los tiene con ese nombre (por eso el error).
    // Si quieres precarga completa, pásame el constructor real de BannerDialog
    // y lo dejo exacto.
    final res = await _showBannerDialog(
      BannerDialog(
        title: 'Editar banner',
        initialTitulo: (data['titulo'] ?? '').toString(),
        initialSubtitulo: (data['subtitulo'] ?? '').toString(),
        // ❌ NO PASAR: initialImagen / initialEstado / initialIdProducto
      ),
    );

    if (res == null) return;

    try {
      await controller.actualizarBanner(
        docId: docId,
        titulo: res.titulo,
        subtitulo: res.subtitulo,
        imagen: res.imagen,
        estado: res.estado,
        idproducto: res.idproducto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBanner(String docId, String titulo) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => ConfirmDeleteDialog(
        title: 'Eliminar banner',
        message: '¿Seguro que quieres eliminar "$titulo"?',
      ),
    );

    if (ok != true) return;

    try {
      await controller.eliminarBanner(docId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputDecoration _searchDecor() {
    return InputDecoration(
      hintText: 'Buscar por título, subtítulo o idproducto...',
      filled: true,
      fillColor: Palette.fieldBg,
      prefixIcon: Icon(
        Icons.search_rounded,
        color: Palette.ink.withValues(alpha: 0.65),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Palette.button.withValues(alpha: 0.35),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Palette.button.withValues(alpha: 0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Palette.primary.withValues(alpha: 0.8),
          width: 1.6,
        ),
      ),
    );
  }

  ButtonStyle _primaryBtn() {
    return ElevatedButton.styleFrom(
      backgroundColor: Palette.button,
      foregroundColor: Palette.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  ButtonStyle _outlineBtn() {
    return OutlinedButton.styleFrom(
      foregroundColor: Palette.ink,
      side: BorderSide(color: Palette.button.withValues(alpha: 0.55)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, c) {
          final isNarrow = c.maxWidth < 640;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestión de Banners',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Palette.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openAddDialog,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Agregar banner'),
                            style: _primaryBtn(),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Text(
                          'Gestión de Banners',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Palette.ink,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _openAddDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Agregar banner'),
                          style: _primaryBtn(),
                        ),
                      ],
                    ),

              const SizedBox(height: 14),

              // ================= BUSCADOR =================
              isNarrow
                  ? Column(
                      children: [
                        TextField(
                          controller: controller.searchCtrl,
                          decoration: _searchDecor(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => controller.searchCtrl.clear(),
                            icon: const Icon(Icons.clear_rounded),
                            label: const Text('Limpiar'),
                            style: _outlineBtn(),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.searchCtrl,
                            decoration: _searchDecor(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => controller.searchCtrl.clear(),
                          icon: const Icon(Icons.clear_rounded),
                          label: const Text('Limpiar'),
                          style: _outlineBtn(),
                        ),
                      ],
                    ),

              const SizedBox(height: 16),

              // ================= GRID =================
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _bannersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return BannerErrorBox(
                        message: 'Error al cargar banners: ${snapshot.error}',
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const BannerLoadingGrid();
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final items = controller.buildCards(docs);

                    if (items.isEmpty) {
                      return const BannerEmptyBox(
                        title: 'No hay banners',
                        subtitle: 'Agrega un banner o ajusta tu búsqueda.',
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Palette.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Palette.button.withValues(alpha: 0.35),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: LayoutBuilder(
                          builder: (context, g) {
                            final isMobile = g.maxWidth < 560;

                            return GridView.builder(
                              padding: const EdgeInsets.all(14),
                              gridDelegate: isMobile
                                  ? const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 1,
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 14,
                                      mainAxisExtent: 300,
                                    )
                                  : const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 520,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 2.65,
                                    ),
                              itemCount: items.length,
                              itemBuilder: (_, i) {
                                final r = items[i];
                                final docId = r['docId'] as String;
                                final titulo = (r['titulo'] ?? '').toString();

                                return BannerCard(
                                  titulo: titulo,
                                  subtitulo: (r['subtitulo'] ?? '').toString(),
                                  imagen: (r['imagen'] ?? '').toString(),
                                  estado: (r['estado'] ?? '').toString(),
                                  onEdit: () => _openEditDialog(
                                    docId: docId,
                                    data: r,
                                  ),
                                  onDelete: () => _deleteBanner(docId, titulo),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
