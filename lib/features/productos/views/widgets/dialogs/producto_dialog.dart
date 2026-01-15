import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:quimisol_web/core/theme/palette.dart';

import '../../../data/almacen_option.dart';
import '../../../data/form_result.dart';
import '../../../data/unidad_option.dart';

class ProductoDialog extends StatefulWidget {
  final String title;
  final List<UnidadOption> unidades;
  final List<AlmacenOption> almacenes;

  final String? initialCodigo;
  final String? initialNombre;
  final String? initialDescripcion;
  final String? initialTipoItem;
  final String? initialUnidadId;
  final String? initialPrecio;

  // ✅ NUEVO: stock inicial
  final String? initialStock;

  final String? initialImagenUrl;
  final String? initialImagenPath;

  final String? initialAlmacenId;

  const ProductoDialog({
    super.key,
    required this.title,
    required this.unidades,
    required this.almacenes,

    this.initialCodigo,
    this.initialNombre,
    this.initialDescripcion,
    this.initialTipoItem,
    this.initialUnidadId,
    this.initialPrecio,
    this.initialStock,
    this.initialImagenUrl,
    this.initialImagenPath,
    this.initialAlmacenId,
  });

  @override
  State<ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends State<ProductoDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigoCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _precioCtrl;

  // ✅ NUEVO: stock controller
  late final TextEditingController _stockCtrl;

  String _tipoItem = 'PRODUCTO';
  String? _unidadId;
  String? _almacenId;

  bool _saving = false;

  Uint8List? _pickedBytes;

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.initialCodigo ?? '');
    _nombreCtrl = TextEditingController(text: widget.initialNombre ?? '');
    _descCtrl = TextEditingController(text: widget.initialDescripcion ?? '');
    _precioCtrl = TextEditingController(text: widget.initialPrecio ?? '0');
    _stockCtrl = TextEditingController(text: widget.initialStock ?? '0');

    _tipoItem = (widget.initialTipoItem?.trim().isNotEmpty ?? false)
        ? widget.initialTipoItem!.trim()
        : 'PRODUCTO';

    final initU = widget.initialUnidadId?.trim();
    if (initU != null && initU.isNotEmpty) {
      _unidadId = initU;
    } else if (widget.unidades.isNotEmpty) {
      _unidadId = widget.unidades.first.id;
    }

    final initA = widget.initialAlmacenId?.trim();
    final existsInit =
        initA != null &&
        initA.isNotEmpty &&
        widget.almacenes.any((a) => a.id == initA);

    if (existsInit) {
      _almacenId = initA;
    } else if (widget.almacenes.isNotEmpty) {
      _almacenId = widget.almacenes.first.id;
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  double _parsePrecio(String v) {
    final cleaned = v.replaceAll(',', '.').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  int _parseStock(String v) {
    final cleaned = v.trim();
    return int.tryParse(cleaned) ?? 0;
  }

  Future<void> _pickImage() async {
    try {
      final Uint8List? bytes = await ImagePickerWeb.getImageAsBytes();
      if (bytes == null) return;
      setState(() => _pickedBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error abriendo selector: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearPickedImage() {
    setState(() => _pickedBytes = null);
  }

  Future<String> _resolveExistingUrl() async {
    return (widget.initialImagenUrl ?? '').trim();
  }

  void _submit() {
    if (_saving) return;
    if (widget.unidades.isEmpty) return;
    if (widget.almacenes.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    final unidad = widget.unidades.firstWhere(
      (u) => u.id == _unidadId,
      orElse: () => widget.unidades.first,
    );

    final almacen = widget.almacenes.firstWhere(
      (a) => a.id == _almacenId,
      orElse: () => widget.almacenes.first,
    );

    setState(() => _saving = true);

    Navigator.pop(
      context,
      ProductoFormResult(
        codigo: _codigoCtrl.text,
        nombre: _nombreCtrl.text,
        descripcion: _descCtrl.text,
        tipoItem: _tipoItem,
        unidadId: unidad.id,
        unidadNombre: unidad.label,
        precio: _parsePrecio(_precioCtrl.text),

        // ✅ NUEVO: stock entero
        stock: _parseStock(_stockCtrl.text),

        imageBytes: _pickedBytes,
        imageName: null,
        almacenId: almacen.id,
        almacenNombre: almacen.label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Palette.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
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
                    // ✅ ALMACÉN
                    DropdownButtonFormField<String>(
                      initialValue: _almacenId,
                      items: widget.almacenes
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _almacenId = v),
                      decoration: InputDecoration(
                        labelText: 'Almacén',
                        filled: true,
                        fillColor: Palette.fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Selecciona un almacén';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codigoCtrl,
                            decoration: InputDecoration(
                              labelText: 'Código (opcional)',
                              filled: true,
                              fillColor: Palette.fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _tipoItem,
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
                            onChanged: (v) =>
                                setState(() => _tipoItem = v ?? _tipoItem),
                            decoration: InputDecoration(
                              labelText: 'Tipo',
                              filled: true,
                              fillColor: Palette.fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        filled: true,
                        fillColor: Palette.fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa un nombre'; 
                        }
                        if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ✅ Unidad + Stock (entero) + Precio
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _unidadId,
                            items: widget.unidades
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u.id,
                                    child: Text(u.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _unidadId = v),
                            decoration: InputDecoration(
                              labelText: 'Unidad',
                              filled: true,
                              fillColor: Palette.fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Selecciona una unidad'; 
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: TextFormField(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Stock',
                              filled: true,
                              fillColor: Palette.fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null) return 'Solo enteros';
                              if (n < 0) return 'No puede ser negativo';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: TextFormField(
                            controller: _precioCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Precio',
                              filled: true,
                              fillColor: Palette.fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) {
                              final p = _parsePrecio(v ?? '');
                              if (p < 0) return 'No puede ser negativo';
                              return null;
                            },
                          ),
                        ),
                      ],
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ✅ IMAGEN
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Palette.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Palette.button.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Imagen (opcional)',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Palette.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: _pickedBytes != null
                                  ? Image.memory(
                                      _pickedBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : FutureBuilder<String>(
                                      future: _resolveExistingUrl(),
                                      builder: (context, snap) {
                                        if (!snap.hasData) {
                                          return Center(
                                            child: Text(
                                              'Sin imagen',
                                              style: TextStyle(
                                                color: Palette.ink.withValues(alpha: 
                                                  0.7,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        final url = (snap.data ?? '').trim();
                                        if (url.isEmpty) {
                                          return Center(
                                            child: Text(
                                              'Sin imagen',
                                              style: TextStyle(
                                                color: Palette.ink.withValues(alpha: 
                                                  0.7,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              'No se pudo cargar',
                                              style: TextStyle(
                                                color: Palette.ink.withValues(alpha: 
                                                  0.75,
                                                ),
                                              ),
                                            ),
                                          ),
                                          loadingBuilder:
                                              (context, child, progress) {
                                                if (progress == null){
                                                  return child;
                                                }
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                        );
                                      },
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _saving ? null : _pickImage,
                                icon: const Icon(Icons.upload_rounded),
                                label: const Text('Seleccionar imagen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.button,
                                  foregroundColor: Palette.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: _saving ? null : _clearPickedImage,
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Quitar'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Palette.ink,
                                  side: BorderSide(
                                    color: Palette.button.withValues(alpha: 0.55),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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