import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';

import 'package:quimisol_web/features/productos/data/almacen_option.dart';
import 'package:quimisol_web/features/productos/data/form_result.dart';
import 'package:quimisol_web/features/productos/data/unidad_option.dart';
import 'package:quimisol_web/features/productos/data/producto_dialog_result.dart';

import '../data/descuento.dart' hide DescuentoDraft;

class ProductoDialogController extends ChangeNotifier {
  ProductoDialogController({
    required this.title,
    required String initialImagenUrl,
    required String? initialCodigo,
    required String? initialNombre,
    required String? initialDescripcion,
    required String? initialTipoItem,
    required String? initialUnidadId,
    required String? initialPrecio,
    required String? initialStock,
    required String? initialAlmacenId,
  })  : existingImageUrl = (initialImagenUrl).trim(),
        codigoCtrl = TextEditingController(text: initialCodigo ?? ''),
        nombreCtrl = TextEditingController(text: initialNombre ?? ''),
        descCtrl = TextEditingController(text: initialDescripcion ?? ''),
        precioCtrl = TextEditingController(text: initialPrecio ?? '0'),
        stockCtrl = TextEditingController(text: initialStock ?? '0'),
        descuentoCtrl = TextEditingController(text: '') {
    tipoItem = (initialTipoItem?.trim().isNotEmpty ?? false)
        ? initialTipoItem!.trim()
        : 'PRODUCTO';

    unidadId = (initialUnidadId?.trim().isNotEmpty ?? false)
        ? initialUnidadId!.trim()
        : null;

    almacenId = (initialAlmacenId?.trim().isNotEmpty ?? false)
        ? initialAlmacenId!.trim()
        : null;

    // refresca preview con escritura
    nombreCtrl.addListener(_bumpPreview);
    precioCtrl.addListener(_bumpPreview);
    stockCtrl.addListener(_bumpPreview);
    descuentoCtrl.addListener(_bumpPreview);
  }

  final String title;

  // controllers
  final TextEditingController codigoCtrl;
  final TextEditingController nombreCtrl;
  final TextEditingController descCtrl;
  final TextEditingController precioCtrl;
  final TextEditingController stockCtrl;

  // descuento
  String? agregarDescuento; // null | "SI" | "NO"
  String descuentoTipo = 'PORCENTAJE'; // PORCENTAJE | MONTO
  final TextEditingController descuentoCtrl;

  // selects
  String tipoItem = 'PRODUCTO';
  String? unidadId;
  String? almacenId;

  // image
  Uint8List? pickedBytes;
  final String existingImageUrl;

  // UI state
  bool saving = false;

  /// Solo para preview
  final ValueNotifier<int> previewTick = ValueNotifier<int>(0);

  bool get descuentoEnabled => agregarDescuento == 'SI';
  bool get hasPickedImage => pickedBytes != null;
  bool get hasExistingImage => existingImageUrl.trim().isNotEmpty;

  void _bumpPreview() => previewTick.value++;

  // --------------------
  // setters
  // --------------------
  void setTipoItem(String v) {
    tipoItem = v;
    notifyListeners();
    _bumpPreview();
  }

  void setUnidadId(String? v) {
    unidadId = v;
    notifyListeners();
    _bumpPreview();
  }

  void setAlmacenId(String? v) {
    almacenId = v;
    notifyListeners();
    _bumpPreview();
  }

  void setAgregarDescuento(String? v) {
    agregarDescuento = v;
    if (agregarDescuento != 'SI') {
      descuentoTipo = 'PORCENTAJE';
      descuentoCtrl.text = '';
    }
    notifyListeners();
    _bumpPreview();
  }

  void setDescuentoTipo(String v) {
    descuentoTipo = v;
    notifyListeners();
    _bumpPreview();
  }

  // --------------------
  // parsing
  // --------------------
  double parsePrecio(String v) =>
      double.tryParse(v.replaceAll(',', '.').trim()) ?? 0.0;

  int parseStock(String v) => int.tryParse(v.trim()) ?? 0;

  double parseDouble(String v) =>
      double.tryParse(v.replaceAll(',', '.').trim()) ?? 0.0;

  double precioBaseNow() => parsePrecio(precioCtrl.text);

  double precioFinalPreview() {
    final base = precioBaseNow();
    if (!descuentoEnabled) return base;

    final val = parseDouble(descuentoCtrl.text);
    if (val <= 0) return base;

    if (descuentoTipo == 'PORCENTAJE') {
      final pct = val.clamp(0, 100);
      final res = base * (1 - (pct / 100));
      return res < 0 ? 0 : res;
    } else {
      final res = base - val;
      return res < 0 ? 0 : res;
    }
  }

  DescuentoDraft? buildDescuentoDraft() {
    if (!descuentoEnabled) return null;

    final val = parseDouble(descuentoCtrl.text);
    if (val <= 0) return null;

    if (descuentoTipo == 'PORCENTAJE') {
      final pct = val.clamp(0, 100);
      if (pct <= 0) return null;
      return DescuentoDraft(tipo: 'PORCENTAJE', valor: pct.toDouble());
    }
    return DescuentoDraft(tipo: 'MONTO', valor: val);
  }

  // --------------------
  // image
  // --------------------
  Future<void> pickImage(BuildContext context) async {
    try {
      final Uint8List? bytes = await ImagePickerWeb.getImageAsBytes();
      if (bytes == null) return;
      pickedBytes = bytes;
      _bumpPreview();
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error abriendo selector: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void clearPickedImage() {
    pickedBytes = null;
    _bumpPreview();
    notifyListeners();
  }

  // --------------------
  // build result
  // --------------------
  ProductoDialogResult buildResult({
    required List<UnidadOption> unidades,
    required List<AlmacenOption> almacenes,
  }) {
    final unidad = unidades.firstWhere(
      (u) => u.id == unidadId,
      orElse: () => unidades.first,
    );

    final almacen = almacenes.firstWhere(
      (a) => a.id == almacenId,
      orElse: () => almacenes.first,
    );

    return ProductoDialogResult(
      producto: ProductoFormResult(
        codigo: codigoCtrl.text,
        nombre: nombreCtrl.text,
        descripcion: descCtrl.text,
        tipoItem: tipoItem,
        unidadId: unidad.id,
        unidadNombre: unidad.label,
        precio: parsePrecio(precioCtrl.text),
        stock: parseStock(stockCtrl.text),
        imageBytes: pickedBytes,
        imageName: null,
        almacenId: almacen.id,
        almacenNombre: almacen.label,
      ),
      descuento: buildDescuentoDraft(),
    );
  }

  @override
  void dispose() {
    nombreCtrl.removeListener(_bumpPreview);
    precioCtrl.removeListener(_bumpPreview);
    stockCtrl.removeListener(_bumpPreview);
    descuentoCtrl.removeListener(_bumpPreview);

    previewTick.dispose();

    codigoCtrl.dispose();
    nombreCtrl.dispose();
    descCtrl.dispose();
    precioCtrl.dispose();
    stockCtrl.dispose();
    descuentoCtrl.dispose();

    super.dispose();
  }
}
