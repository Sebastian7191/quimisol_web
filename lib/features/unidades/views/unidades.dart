import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quimisol_web/core/theme/palette.dart';
import '../../../shared/dialogs/delete_dialog.dart';
import '../controllers/unidades_controller.dart';

import 'widgets/dialogs/form_result.dart';
import 'widgets/dialogs/unidad_dialog.dart';
import 'widgets/un_empty_box.dart';
import 'widgets/un_error_box.dart';
import 'widgets/un_loading_table.dart';

class UnidadesPage extends StatefulWidget {
  const UnidadesPage({super.key});

  @override
  State<UnidadesPage> createState() => _UnidadesPageState();
}

class _UnidadesPageState extends State<UnidadesPage> {
  final controller = UnidadesController();

  @override
  void initState() {
    super.initState();
    // Rebuild UI when the controller's search text changes
    controller.searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _unidadesStream() =>
      controller.unidadesStream();

  Future<void> _openAddDialog() async {
    final res = await showDialog<UnidadFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UnidadDialog(title: 'Agregar unidad'),
    );

    if (res == null) return;

    try {
      await controller.crearUnidad(
        nombre: res.nombre,
        abreviatura: res.abreviatura,
        descripcion: res.descripcion,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidad agregada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar unidad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEditDialog({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final res = await showDialog<UnidadFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UnidadDialog(
        title: 'Editar unidad',
        initialNombre: (data['nombre'] ?? '').toString(),
        initialAbreviatura: (data['abreviatura'] ?? '').toString(),
        initialDescripcion: (data['descripcion'] ?? '').toString(),
      ),
    );

    if (res == null) return;

    try {
      await controller.actualizarUnidad(
        id: id,
        nombre: res.nombre,
        abreviatura: res.abreviatura,
        descripcion: res.descripcion,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unidad actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar unidad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUnidad(String id, String nombre) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ConfirmDeleteDialog(
      title: 'Eliminar unidad',
      message: '¿Seguro que quieres eliminar "$nombre"?',
    ),
  );

  if (ok != true) return;

  try {
    await controller.eliminarUnidad(id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unidad eliminada')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar unidad: $e'),
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
                'Gestión de Unidades',
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
                label: const Text('Agregar unidad'),
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
                    hintText: 'Buscar por nombre o abreviatura...',
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

          // ================= LISTADO =================
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _unidadesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return UnidadesErrorBox(
                    message: 'Error al cargar unidades: ${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const UnidadesLoadingTable();
                }

                final docs = snapshot.data?.docs ?? [];

                final filtered = controller.buildRows(docs);

                if (filtered.isEmpty) {
                  return const UnidadesEmptyBox(
                    title: 'No hay unidades',
                    subtitle: 'Agrega una unidad o ajusta tu búsqueda.',
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Palette.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Palette.button.withValues(alpha: 0.35)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 52,
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 72,
                        columnSpacing: 18,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Palette.ink,
                        ),
                        columns: const [
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Abrev.')),
                          DataColumn(label: Text('Descripción')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: filtered.map((r) {
                          final id = r['id'] as String;
                          final nombre = r['nombre'] as String;
                          final abrev = r['abreviatura'] as String;
                          final desc = r['descripcion'] as String;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  nombre.isEmpty ? '-' : nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(Text(abrev.isEmpty ? '-' : abrev)),
                              DataCell(
                                SizedBox(
                                  width: 420,
                                  child: Text(
                                    desc.isEmpty ? '-' : desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar',
                                      onPressed: () => _openEditDialog(
                                        id: id,
                                        data: {
                                          'nombre': nombre,
                                          'abreviatura': abrev,
                                          'descripcion': desc,
                                        },
                                      ),
                                      icon: Icon(
                                        Icons.edit_rounded,
                                        color: Palette.primary,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      onPressed: () =>
                                          _deleteUnidad(id, nombre),
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: Palette.statsDanger.withValues(alpha: 
                                          0.95,
                                        ),
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
  }
}