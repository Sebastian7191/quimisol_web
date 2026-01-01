import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quimisol_web/core/theme/palette.dart';

class AlmacenesPage extends StatefulWidget {
  const AlmacenesPage({super.key});

  @override
  State<AlmacenesPage> createState() => _AlmacenesPageState();
}

class _AlmacenesPageState extends State<AlmacenesPage> {
  String selectedDepto = 'Todos';

  final List<String> departamentos = const [
    'Todos',
    'La Paz',
    'Cochabamba',
    'Santa Cruz',
    'Oruro',
    'Potosí',
    'Chuquisaca',
    'Tarija',
    'Beni',
    'Pando',
  ];

  /// ===========================
  /// ✅ IMPRIMIR LINK ÍNDICE EN CONSOLA
  /// ===========================
  void _printFirestoreIndexLink(Object error) {
    final raw = error.toString();

    final match = RegExp(
      r'(https:\/\/console\.firebase\.google\.com\/[^\s]+)',
    ).firstMatch(raw);

    if (match != null) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ CREA EL ÍNDICE AQUÍ:');
      debugPrint(match.group(1));
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } else {
      debugPrint('🔥 Firestore error (sin link encontrado): $raw');
    }
  }

  /// ===========================
  /// 🔥 GUARDAR EN FIRESTORE
  /// ===========================
  Future<void> _guardarAlmacenFirestore({
    required String nombre,
    required String departamento,
    required String descripcion,
  }) async {
    final ref = FirebaseFirestore.instance.collection('almacenes');

    await ref.doc().set({
      'nombre': nombre.trim(),
      'departamento': departamento,
      'descripcion': descripcion.trim(),
      'activo': true,
      'createdAt': FieldValue.serverTimestamp(),
      // opcionales:
      'productos': 0,
      'stock': 0,
    });
  }

  Future<void> _openAddAlmacenDialog() async {
    final res = await showDialog<_NewAlmacenFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddAlmacenDialog(),
    );

    if (res == null) return;

    try {
      await _guardarAlmacenFirestore(
        nombre: res.nombre,
        departamento: res.departamento,
        descripcion: res.descripcion,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Almacén agregado correctamente')),
        );
      }
    } catch (e) {
      debugPrint('🔥 Error guardando almacén: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar almacén: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ===========================
  /// 🔥 STREAM FIRESTORE
  /// ===========================
  Stream<QuerySnapshot<Map<String, dynamic>>> _almacenesStream() {
    return FirebaseFirestore.instance
        .collection('almacenes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ================= HEADER =================
          Row(
            children: [
              const Text(
                'Gestión de Almacenes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Palette.ink,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openAddAlmacenDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar almacén'),
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

          const SizedBox(height: 16),

          /// ================= FILTRO DEPARTAMENTOS =================
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: departamentos.map((d) {
              final selected = d == selectedDepto;
              return ChoiceChip(
                label: Text(d),
                selected: selected,
                selectedColor: Palette.button,
                backgroundColor: Palette.card,
                labelStyle: TextStyle(
                  color: selected ? Palette.white : Palette.ink,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => selectedDepto = d),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          /// ================= LISTADO DESDE FIRESTORE =================
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _almacenesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // ✅ imprime el link del índice en la terminal
                  _printFirestoreIndexLink(snapshot.error!);

                  return _ErrorBox(
                    message: 'Error al cargar almacenes: ${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingGrid();
                }

                final docs = snapshot.data?.docs ?? [];

                final all = docs.map((d) {
                  final data = d.data();
                  return {
                    'id': d.id,
                    'nombre': (data['nombre'] ?? '').toString(),
                    'departamento': (data['departamento'] ?? '').toString(),
                    'descripcion': (data['descripcion'] ?? '').toString(),
                    'productos': (data['productos'] ?? 0),
                    'stock': (data['stock'] ?? 0),
                  };
                }).toList();

                final filtered = selectedDepto == 'Todos'
                    ? all
                    : all
                          .where((a) => a['departamento'] == selectedDepto)
                          .toList();

                if (filtered.isEmpty) {
                  return const _EmptyBox(
                    title: 'No hay almacenes',
                    subtitle:
                        'Agrega un almacén o cambia el filtro de departamento.',
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final a = filtered[i];

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        // Si tienes página de detalle luego:
                        Modular.to.pushNamed('/almacenes/${a['id']}');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Palette.button.withOpacity(0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a['nombre'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Palette.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a['departamento'] as String,
                              style: TextStyle(
                                color: Palette.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                _Stat(
                                  label: 'Productos',
                                  value: (a['productos'] ?? 0).toString(),
                                ),
                                const SizedBox(width: 16),
                                _Stat(
                                  label: 'Stock',
                                  value: (a['stock'] ?? 0).toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Palette.ink.withOpacity(0.6), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Palette.ink,
          ),
        ),
      ],
    );
  }
}

/// ===========================
/// Loading / Empty / Error UI
/// ===========================
class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Palette.button.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 160, color: Palette.card),
            const SizedBox(height: 10),
            Container(height: 12, width: 100, color: Palette.card),
            const Spacer(),
            Row(
              children: [
                Container(height: 12, width: 90, color: Palette.card),
                const SizedBox(width: 16),
                Container(height: 12, width: 70, color: Palette.card),
              ],
            ),
          ],
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
            Icon(
              Icons.warehouse_rounded,
              size: 44,
              color: Palette.primary.withOpacity(0.85),
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
            Icon(
              Icons.error_outline_rounded,
              color: Palette.statsDanger.withOpacity(0.9),
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

/// ===========================
/// Dialog Agregar Almacén
/// ===========================
class _AddAlmacenDialog extends StatefulWidget {
  const _AddAlmacenDialog();

  @override
  State<_AddAlmacenDialog> createState() => _AddAlmacenDialogState();
}

class _AddAlmacenDialogState extends State<_AddAlmacenDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  String _depto = 'La Paz';
  bool _saving = false;

  final List<String> deptosBolivia = const [
    'La Paz',
    'Cochabamba',
    'Santa Cruz',
    'Oruro',
    'Potosí',
    'Chuquisaca',
    'Tarija',
    'Beni',
    'Pando',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    Navigator.pop(
      context,
      _NewAlmacenFormResult(
        nombre: _nombreCtrl.text,
        departamento: _depto,
        descripcion: _descripcionCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Palette.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agregar almacén',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
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
                        labelText: 'Nombre del almacén',
                        filled: true,
                        fillColor: Palette.fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Ingresa un nombre';
                        if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _depto,
                      items: deptosBolivia
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _depto = v ?? _depto),
                      decoration: InputDecoration(
                        labelText: 'Departamento',
                        filled: true,
                        fillColor: Palette.fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionCtrl,
                      minLines: 3,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Palette.ink,
                        side: BorderSide(
                          color: Palette.button.withOpacity(0.55),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
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
                              style: TextStyle(fontWeight: FontWeight.w800),
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

class _NewAlmacenFormResult {
  final String nombre;
  final String departamento;
  final String descripcion;

  _NewAlmacenFormResult({
    required this.nombre,
    required this.departamento,
    required this.descripcion,
  });
}
