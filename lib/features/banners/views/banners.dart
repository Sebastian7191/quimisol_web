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

  Future<void> _openAddDialog() async {
    final res = await showDialog<BannerFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BannerDialog(title: 'Agregar banner'),
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
    final res = await showDialog<BannerFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BannerDialog(
        title: 'Editar banner',
        initialTitulo: (data['titulo'] ?? '').toString(),
        initialSubtitulo: (data['subtitulo'] ?? '').toString(),
        initialImagen: (data['imagen'] ?? '').toString(),
        initialEstado: (data['estado'] ?? 'INACTIVO').toString(),
        initialIdProducto: (data['idproducto'] ?? '').toString(),
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
    final ok = await showDialog<bool>(
      context: context,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Row(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.button,
                  foregroundColor: Palette.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ================= BUSCADOR =================
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.searchCtrl,
                  decoration: InputDecoration(
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
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => controller.searchCtrl.clear(),
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Limpiar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Palette.ink,
                  side: BorderSide(color: Palette.button.withValues(alpha: 0.55)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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
                    child: GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 520, // ✅ auto columnas
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 2.65,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final r = items[i];

                        final docId = r['docId'] as String;
                        final titulo = r['titulo'] as String;

                        return BannerCard(
                          titulo: titulo,
                          subtitulo: r['subtitulo'] as String,
                          imagen: r['imagen'] as String,
                          estado: r['estado'] as String,
                          onEdit: () => _openEditDialog(
                            docId: docId,
                            data: r,
                          ),
                          onDelete: () => _deleteBanner(docId, titulo),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
