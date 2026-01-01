import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quimisol_web/core/theme/palette.dart';

class UnidadesPage extends StatefulWidget {
  const UnidadesPage({super.key});

  @override
  State<UnidadesPage> createState() => _UnidadesPageState();
}

class _UnidadesPageState extends State<UnidadesPage> {
  final _searchCtrl = TextEditingController();

  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('unidades');

  Stream<QuerySnapshot<Map<String, dynamic>>> _unidadesStream() {
    // ✅ Trae todo (sin where) y sin orderBy para evitar problemas con createdAt faltante
    return _ref.snapshots();
  }

  Future<void> _openAddDialog() async {
    final res = await showDialog<_UnidadFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _UnidadDialog(title: 'Agregar unidad'),
    );

    if (res == null) return;

    try {
      await _ref.doc().set({
        'nombre': res.nombre.trim(),
        'abreviatura': res.abreviatura.trim(),
        'descripcion': res.descripcion.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
    final res = await showDialog<_UnidadFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UnidadDialog(
        title: 'Editar unidad',
        initialNombre: (data['nombre'] ?? '').toString(),
        initialAbreviatura: (data['abreviatura'] ?? '').toString(),
        initialDescripcion: (data['descripcion'] ?? '').toString(),
      ),
    );

    if (res == null) return;

    try {
      await _ref.doc(id).update({
        'nombre': res.nombre.trim(),
        'abreviatura': res.abreviatura.trim(),
        'descripcion': res.descripcion.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidad actualizada')),
        );
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
      builder: (_) => AlertDialog(
        backgroundColor: Palette.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Eliminar unidad',
          style: TextStyle(fontWeight: FontWeight.w900, color: Palette.ink),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "$nombre"?',
          style: TextStyle(color: Palette.ink.withOpacity(0.85)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _ref.doc(id).delete();

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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o abreviatura...',
                    filled: true,
                    fillColor: Palette.fieldBg,
                    prefixIcon: Icon(Icons.search_rounded, color: Palette.ink.withOpacity(0.65)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Palette.button.withOpacity(0.35)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Palette.button.withOpacity(0.25)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Palette.primary.withOpacity(0.8), width: 1.6),
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
                  side: BorderSide(color: Palette.button.withOpacity(0.55)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  return _ErrorBox(message: 'Error al cargar unidades: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingTable();
                }

                final docs = snapshot.data?.docs ?? [];

                // Map + sort por createdAt si existe
                final rows = docs.map((d) {
                  final data = d.data();
                  final ts = data['createdAt'];
                  DateTime? created;
                  if (ts is Timestamp) created = ts.toDate();

                  return {
                    'id': d.id,
                    'nombre': (data['nombre'] ?? '').toString(),
                    'abreviatura': (data['abreviatura'] ?? '').toString(),
                    'descripcion': (data['descripcion'] ?? '').toString(),
                    'createdAt': created,
                  };
                }).toList();

                rows.sort((a, b) {
                  final da = a['createdAt'] as DateTime?;
                  final db = b['createdAt'] as DateTime?;
                  if (da == null && db == null) return 0;
                  if (da == null) return 1;
                  if (db == null) return -1;
                  return db.compareTo(da);
                });

                // filtro search
                final filtered = _search.isEmpty
                    ? rows
                    : rows.where((r) {
                        final n = (r['nombre'] as String).toLowerCase();
                        final ab = (r['abreviatura'] as String).toLowerCase();
                        return n.contains(_search) || ab.contains(_search);
                      }).toList();

                if (filtered.isEmpty) {
                  return const _EmptyBox(
                    title: 'No hay unidades',
                    subtitle: 'Agrega una unidad o ajusta tu búsqueda.',
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Palette.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Palette.button.withOpacity(0.35)),
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
                              DataCell(Text(
                                nombre.isEmpty ? '-' : nombre,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              )),
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
                                      onPressed: () => _openEditDialog(id: id, data: {
                                        'nombre': nombre,
                                        'abreviatura': abrev,
                                        'descripcion': desc,
                                      }),
                                      icon: Icon(Icons.edit_rounded, color: Palette.primary),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      onPressed: () => _deleteUnidad(id, nombre),
                                      icon: Icon(Icons.delete_outline_rounded,
                                          color: Palette.statsDanger.withOpacity(0.95)),
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

/// ===========================
/// Loading / Empty / Error UI
/// ===========================
class _LoadingTable extends StatelessWidget {
  const _LoadingTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.button.withOpacity(0.25)),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyBox({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Palette.button.withOpacity(0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.straighten_rounded, size: 44, color: Palette.primary.withOpacity(0.85)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.ink.withOpacity(0.75)),
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
          border: Border.all(color: Palette.statsDanger.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Palette.statsDanger.withOpacity(0.9)),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Palette.ink))),
          ],
        ),
      ),
    );
  }
}

/// ===========================
/// Dialog Unidad (Add/Edit)
/// ===========================
class _UnidadDialog extends StatefulWidget {
  final String title;
  final String? initialNombre;
  final String? initialAbreviatura;
  final String? initialDescripcion;

  const _UnidadDialog({
    required this.title,
    this.initialNombre,
    this.initialAbreviatura,
    this.initialDescripcion,
  });

  @override
  State<_UnidadDialog> createState() => _UnidadDialogState();
}

class _UnidadDialogState extends State<_UnidadDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _abrevCtrl;
  late final TextEditingController _descCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initialNombre ?? '');
    _abrevCtrl = TextEditingController(text: widget.initialAbreviatura ?? '');
    _descCtrl = TextEditingController(text: widget.initialDescripcion ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _abrevCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    Navigator.pop(
      context,
      _UnidadFormResult(
        nombre: _nombreCtrl.text,
        abreviatura: _abrevCtrl.text,
        descripcion: _descCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Palette.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la unidad (Ej: Kilogramo)',
                        filled: true,
                        fillColor: Palette.fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresa un nombre';
                        if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _abrevCtrl,
                      decoration: InputDecoration(
                        labelText: 'Abreviatura (Ej: Kg, Lt, Und)',
                        filled: true,
                        fillColor: Palette.fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      minLines: 3,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        filled: true,
                        fillColor: Palette.fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Palette.ink,
                        side: BorderSide(color: Palette.button.withOpacity(0.55)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w800)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w900)),
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

class _UnidadFormResult {
  final String nombre;
  final String abreviatura;
  final String descripcion;

  _UnidadFormResult({
    required this.nombre,
    required this.abreviatura,
    required this.descripcion,
  });
}
