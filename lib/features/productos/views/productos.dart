// lib/features/admin/productos/productos_page.dart
//
// ✅ Firestore: collection('productos') + collection('unidades') + collection('almacenes')
// ✅ Imágenes: Firebase Storage bucket gs://quimisol-4f159.firebasestorage.app
// ✅ Carpeta: productos_e_insumos/{productId}/{filename}
// ✅ Picker WEB: image_picker_web
//
// Requiere en pubspec.yaml:
//   firebase_storage: ^12.1.0
//   image_picker_web: ^4.0.0

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quimisol_web/features/productos/data/producto_dialog_result.dart';
import '../controllers/products_controller.dart';
import '../data/producto_row.dart';
import '../data/unidad_option.dart';
import '../data/almacen_option.dart';

// ✅ NUEVO: dialog extraído
import '../widgets/producto_dialog.dart';

import 'package:quimisol_web/core/theme/palette.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  String _tipo = 'Todos'; // Todos | PRODUCTO | INSUMO

  final controller = ProductosController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _search = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _productosStream() {
    return controller.productosStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _unidadesStream() {
    return controller.unidadesStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _almacenesStream() {
    return controller.almacenesStream();
  }

  Future<void> _openAddDialog({
    required List<UnidadOption> unidades,
    required List<AlmacenOption> almacenes,
  }) async {
    if (almacenes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Primero crea al menos un almacén en la colección "almacenes".',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final res = await showDialog<ProductoDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductoDialog(
        title: 'Agregar producto',
        unidades: unidades,
        almacenes: almacenes,
      ),
    );

    if (res == null) return;

    try {
      // ✅ Ahora el producto está dentro de res.producto
      await controller.crearProducto(
        res.producto,
        descuento: res.descuento,
        promoBannerEnabled: res.promoBannerEnabled, // ✅ NUEVO
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto agregado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEditDialog({
    required String id,
    required ProductoRow product,
    required List<UnidadOption> unidades,
    required List<AlmacenOption> almacenes,
  }) async {
    final res = await showDialog<ProductoDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductoDialog(
        title: 'Editar producto',
        unidades: unidades,
        almacenes: almacenes,
        initialCodigo: product.codigo,
        initialNombre: product.nombre,
        initialDescripcion: product.descripcion,
        initialTipoItem: product.tipoItem,
        initialUnidadId: product.unidadId,
        initialPrecio: product.precio.toString(),
        initialStock: product.stock.toString(),
        initialImagenUrl: product.imagenUrl,
        initialImagenPath: product.imagenPath,
        initialAlmacenId: product.almacenId,
      ),
    );

    if (res == null) return;

    try {
      await controller.actualizarProducto(
        id,
        res.producto,
        existingImagenUrl: product.imagenUrl,
        existingImagenPath: product.imagenPath,
        descuento: res.descuento,
        promoBannerEnabled: res.promoBannerEnabled, // ✅ NUEVO
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto actualizado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProducto(
    String id,
    String nombre, {
    String? imagenPath,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Palette.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Eliminar producto',
          style: TextStyle(fontWeight: FontWeight.w900, color: Palette.ink),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "$nombre"?',
          style: TextStyle(color: Palette.ink.withValues(alpha: 0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.statsDanger,
              foregroundColor: Palette.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await controller.eliminarProducto(id, imagenPath);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openImageViewer({
    required String title,
    required String imagenPath,
    required String imagenUrl,
  }) {
    showDialog(
      context: context,
      builder: (_) => _ImageViewerDialog(
        title: title,
        imagenPath: imagenPath,
        imagenUrl: imagenUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _unidadesStream(),
      builder: (context, unidadesSnap) {
        if (unidadesSnap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: _ErrorBox(
              message: 'Error al cargar unidades: ${unidadesSnap.error}',
            ),
          );
        }

        final unidadesDocs = unidadesSnap.data?.docs ?? [];
        final unidades = unidadesDocs.map((d) {
          final data = d.data();
          return UnidadOption(
            id: d.id,
            nombre: (data['nombre'] ?? '').toString(),
            abreviatura: (data['abreviatura'] ?? '').toString(),
          );
        }).toList();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _almacenesStream(),
          builder: (context, almacenesSnap) {
            if (almacenesSnap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: _ErrorBox(
                  message: 'Error al cargar almacenes: ${almacenesSnap.error}',
                ),
              );
            }

            final almacenesDocs = almacenesSnap.data?.docs ?? [];
            final almacenes = almacenesDocs
                .map((d) {
                  final data = d.data();
                  return AlmacenOption(
                    id: d.id,
                    nombre: (data['nombre'] ?? '').toString(),
                    activo: (data['activo'] is bool)
                        ? (data['activo'] as bool)
                        : true,
                  );
                })
                .where((a) => a.activo)
                .toList();

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= HEADER =================
                  Row(
                    children: [
                      const Text(
                        'Gestión de Productos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Palette.ink,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: (unidades.isEmpty || almacenes.isEmpty)
                            ? null
                            : () => _openAddDialog(
                                unidades: unidades,
                                almacenes: almacenes,
                              ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Agregar producto'),
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
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (unidades.isEmpty || almacenes.isEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Palette.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Palette.button.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Palette.ink.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              unidades.isEmpty
                                  ? 'Primero crea al menos una unidad (Ej: Kilogramo, Litro, Unidad).'
                                  : 'Primero crea al menos un almacén en la colección "almacenes".',
                              style: TextStyle(
                                color: Palette.ink.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // ================= BUSCADOR =================
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Buscar por código o nombre...',
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
                        onPressed: () => _searchCtrl.clear(),
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text('Limpiar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.ink,
                          side: BorderSide(
                            color: Palette.button.withValues(alpha: 0.55),
                          ),
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

                  const SizedBox(height: 10),

                  // ================= FILTRO TIPO =================
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Todos', 'PRODUCTO', 'INSUMO'].map((t) {
                      final selected = _tipo == t;
                      return ChoiceChip(
                        label: Text(t == 'Todos' ? 'Todos' : t),
                        selected: selected,
                        selectedColor: Palette.button,
                        backgroundColor: Palette.card,
                        labelStyle: TextStyle(
                          color: selected ? Palette.white : Palette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => setState(() => _tipo = t),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // ================= LISTADO =================
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _productosStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _ErrorBox(
                            message:
                                'Error al cargar productos: ${snapshot.error}',
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _LoadingTable(
                            icon: Icons.inventory_2_rounded,
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        final productos = docs
                            .map((d) => controller.mapProducto(d))
                            .toList();

                        productos.sort((a, b) {
                          final da = a.createdAt;
                          final db = b.createdAt;
                          if (da == null && db == null) return 0;
                          if (da == null) return 1;
                          if (db == null) return -1;
                          return db.compareTo(da);
                        });

                        final filtered = controller.filterProductos(
                          rows: productos,
                          search: _search,
                          tipo: _tipo,
                        );

                        if (filtered.isEmpty) {
                          return const _EmptyBox(
                            title: 'No hay productos',
                            subtitle:
                                'Agrega un producto o ajusta tus filtros.',
                            icon: Icons.inventory_2_rounded,
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
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowHeight: 52,
                                dataRowMinHeight: 64,
                                dataRowMaxHeight: 84,
                                columnSpacing: 18,
                                headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Palette.ink,
                                ),
                                columns: const [
                                  DataColumn(label: Text('Imagen')),
                                  DataColumn(label: Text('Código')),
                                  DataColumn(label: Text('Nombre')),
                                  DataColumn(label: Text('Descripción')),
                                  DataColumn(label: Text('Tipo')),
                                  DataColumn(label: Text('Unidad')),
                                  DataColumn(label: Text('Stock')),
                                  DataColumn(label: Text('Precio')),
                                  DataColumn(label: Text('Acciones')),
                                ],
                                rows: filtered.map((p) {
                                  final id = p.id;
                                  final codigo = p.codigo;
                                  final nombre = p.nombre;
                                  final tipoItem = p.tipoItem;
                                  final unidadNombre = p.unidadNombre;
                                  final desc = p.descripcion;
                                  final stock = p.stock;
                                  final precio = p.precio;
                                  final imagenUrl = p.imagenUrl.trim();
                                  final imagenPath = p.imagenPath.trim();

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        InkWell(
                                          onTap:
                                              (imagenPath.isEmpty &&
                                                  imagenUrl.isEmpty)
                                              ? null
                                              : () => _openImageViewer(
                                                  title: nombre,
                                                  imagenPath: imagenPath,
                                                  imagenUrl: imagenUrl,
                                                ),
                                          child: _ProductoThumb(
                                            imagenPath: imagenPath,
                                            imagenUrl: imagenUrl,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          codigo.isEmpty ? '-' : codigo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 240,
                                          child: Text(
                                            nombre.isEmpty ? '-' : nombre,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 320,
                                          child: Text(
                                            desc.trim().isEmpty
                                                ? '-'
                                                : desc.trim(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Palette.ink.withValues(
                                                alpha: 0.85,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(_ChipTipo(tipoItem: tipoItem)),
                                      DataCell(
                                        Text(
                                          unidadNombre.isEmpty
                                              ? '-'
                                              : unidadNombre,
                                        ),
                                      ),
                                      DataCell(Text(stock.toString())),
                                      DataCell(Text(precio.toStringAsFixed(2))),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              tooltip: 'Editar',
                                              onPressed: () => _openEditDialog(
                                                id: id,
                                                product: p,
                                                unidades: unidades,
                                                almacenes: almacenes,
                                              ),
                                              icon: Icon(
                                                Icons.edit_rounded,
                                                color: Palette.primary,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Eliminar',
                                              onPressed: () => _deleteProducto(
                                                id,
                                                nombre,
                                                imagenPath: imagenPath,
                                              ),
                                              icon: Icon(
                                                Icons.delete_outline_rounded,
                                                color: Palette.statsDanger
                                                    .withValues(alpha: 0.95),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ChipTipo extends StatelessWidget {
  final String tipoItem;
  const _ChipTipo({required this.tipoItem});

  @override
  Widget build(BuildContext context) {
    final isProducto = tipoItem == 'PRODUCTO';
    final bg = isProducto
        ? Palette.statsSuccess.withValues(alpha: 0.15)
        : Palette.statsWarning.withValues(alpha: 0.18);
    final fg = isProducto ? Palette.statsSuccess : Palette.statsWarning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        tipoItem,
        style: TextStyle(
          color: fg.withValues(alpha: 0.95),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ✅ Miniatura: WEB usa bytes, móvil usa Image.network
class _ProductoThumb extends StatelessWidget {
  final String imagenPath;
  final String imagenUrl;

  const _ProductoThumb({required this.imagenPath, required this.imagenUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Palette.fieldBg,
        border: Border.all(color: Palette.button.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Palette.ink.withValues(alpha: 0.35),
        ),
      ),
    );

    final url = imagenUrl.trim();
    if (url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _ImageViewerDialog extends StatelessWidget {
  final String title;
  final String imagenPath;
  final String imagenUrl;

  const _ImageViewerDialog({
    required this.title,
    required this.imagenPath,
    required this.imagenUrl,
  });

  Widget _buildImageContent(String imagenUrl) {
    final url = imagenUrl.trim();
    if (url.isEmpty) {
      return Center(
        child: Text(
          'Sin imagen',
          style: TextStyle(color: Palette.ink.withValues(alpha: 0.7)),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Text(
          'No se pudo cargar la imagen',
          style: TextStyle(color: Palette.ink.withValues(alpha: 0.75)),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Palette.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Palette.ink,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildImageContent(imagenUrl),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.button,
                    foregroundColor: Palette.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===========================
/// Loading / Empty / Error UI
/// ===========================
class _LoadingTable extends StatelessWidget {
  final IconData icon;
  const _LoadingTable({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.button.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 42,
                color: Palette.primary.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyBox({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Palette.button.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: Palette.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.ink.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Palette.statsDanger.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Palette.statsDanger.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Palette.ink)),
            ),
          ],
        ),
      ),
    );
  }
}
