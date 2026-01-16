// lib/features/productos/controllers/producto_dialog_controller.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';

import 'package:quimisol_web/features/productos/data/almacen_option.dart';
import 'package:quimisol_web/features/productos/data/form_result.dart';
import 'package:quimisol_web/features/productos/data/unidad_option.dart';
import 'package:quimisol_web/features/productos/data/producto_dialog_result.dart';

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

    // ✅ NUEVO: categoría (para editar)
    String? initialCategoriaId,
    String? initialCategoriaNombre,
  })  : existingImageUrl = initialImagenUrl.trim(),
        codigoCtrl = TextEditingController(text: initialCodigo ?? ''),
        nombreCtrl = TextEditingController(text: initialNombre ?? ''),
        descCtrl = TextEditingController(text: initialDescripcion ?? ''),
        precioCtrl = TextEditingController(text: initialPrecio ?? '0'),
        stockCtrl = TextEditingController(text: initialStock ?? '0'),
        descuentoCtrl = TextEditingController(text: ''),
        // ✅ Promo banner defaults
        promoTitleCtrl = TextEditingController(text: 'New Collection'),
        promoSubtitleCtrl = TextEditingController(
          text: 'Discount 50% for\nthe first transaction',
        ),
        promoButtonTextCtrl = TextEditingController(text: 'Shop Now'),
        promoImageUrlCtrl = TextEditingController(text: '') {
    tipoItem = (initialTipoItem?.trim().isNotEmpty ?? false)
        ? initialTipoItem!.trim()
        : 'PRODUCTO';

    unidadId = (initialUnidadId?.trim().isNotEmpty ?? false)
        ? initialUnidadId!.trim()
        : null;

    almacenId = (initialAlmacenId?.trim().isNotEmpty ?? false)
        ? initialAlmacenId!.trim()
        : null;

    // ✅ categoría inicial (para editar)
    categoriaId = (initialCategoriaId?.trim().isNotEmpty ?? false)
        ? initialCategoriaId!.trim()
        : null;

    categoriaNombre = (initialCategoriaNombre?.trim().isNotEmpty ?? false)
        ? initialCategoriaNombre!.trim()
        : null;

    // refresca preview con escritura
    nombreCtrl.addListener(_bumpPreview);
    precioCtrl.addListener(_bumpPreview);
    stockCtrl.addListener(_bumpPreview);
    descuentoCtrl.addListener(_bumpPreview);

    // ✅ refresca preview con escritura en promo banner
    promoTitleCtrl.addListener(_bumpPreview);
    promoSubtitleCtrl.addListener(_bumpPreview);
    promoButtonTextCtrl.addListener(_bumpPreview);
    promoImageUrlCtrl.addListener(_bumpPreview);
  }

  final String title;

  // --------------------
  // text controllers
  // --------------------
  final TextEditingController codigoCtrl;
  final TextEditingController nombreCtrl;
  final TextEditingController descCtrl;
  final TextEditingController precioCtrl;
  final TextEditingController stockCtrl;

  // --------------------
  // descuento
  // --------------------
  String? agregarDescuento; // null | "SI" | "NO"
  String descuentoTipo = 'PORCENTAJE'; // PORCENTAJE | MONTO
  final TextEditingController descuentoCtrl;

  // --------------------
  // ✅ promo banner
  // --------------------
  bool promoBannerEnabled = false;
  final TextEditingController promoTitleCtrl;
  final TextEditingController promoSubtitleCtrl;
  final TextEditingController promoButtonTextCtrl;
  final TextEditingController promoImageUrlCtrl;

  // --------------------
  // ✅ categoría
  // --------------------
  String? categoriaId;
  String? categoriaNombre;

  // --------------------
  // selects
  // --------------------
  String tipoItem = 'PRODUCTO';
  String? unidadId;
  String? almacenId;

  // --------------------
  // image
  // --------------------
  Uint8List? pickedBytes;
  final String existingImageUrl;

  // --------------------
  // UI state
  // --------------------
  bool saving = false;

  /// Solo para preview (si tu preview panel usa esto)
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

  /// ✅ set categoría (ACEPTA NULL) -> para "— Seleccionar —"
  void setCategoria(String? id, String? nombre) {
    categoriaId = id;
    categoriaNombre = nombre;
    notifyListeners();
    _bumpPreview();
  }

  void setAgregarDescuento(String? v) {
    agregarDescuento = v;

    if (agregarDescuento != 'SI') {
      descuentoTipo = 'PORCENTAJE';
      descuentoCtrl.text = '';

      // ✅ si quitan descuento, apagamos banner
      promoBannerEnabled = false;
    }

    notifyListeners();
    _bumpPreview();
  }

  void setDescuentoTipo(String v) {
    descuentoTipo = v;
    notifyListeners();
    _bumpPreview();
  }

  // ✅ promo banner enable
  void setPromoBannerEnabled(bool v) {
    promoBannerEnabled = v;
    notifyListeners();
    _bumpPreview();
  }

  // --------------------
  // helpers promo (para preview)
  // --------------------
  String get promoTitleSafe =>
      promoTitleCtrl.text.trim().isEmpty ? 'New Collection' : promoTitleCtrl.text.trim();

  String get promoSubtitleSafe => promoSubtitleCtrl.text.trim().isEmpty
      ? 'Discount 50% for\nthe first transaction'
      : promoSubtitleCtrl.text;

  String get promoButtonTextSafe =>
      promoButtonTextCtrl.text.trim().isEmpty ? 'Shop Now' : promoButtonTextCtrl.text.trim();

  String? get promoImageUrlSafe {
    final v = promoImageUrlCtrl.text.trim();
    return v.isEmpty ? null : v;
  }

  // --------------------
  // parsing
  // --------------------
  double parsePrecio(String v) => double.tryParse(v.replaceAll(',', '.').trim()) ?? 0.0;

  int parseStock(String v) => int.tryParse(v.trim()) ?? 0;

  double parseDouble(String v) => double.tryParse(v.replaceAll(',', '.').trim()) ?? 0.0;

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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error abriendo selector: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void clearPickedImage() {
    pickedBytes = null;
    _bumpPreview();
    notifyListeners();
  }

  // --------------------
  // build result
  // ✅ AQUÍ ESTÁ lo importante: incluye categoriaId/categoriaNombre
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

        // ✅ NUEVO
        categoriaId: categoriaId,
        categoriaNombre: categoriaNombre,
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

    promoTitleCtrl.removeListener(_bumpPreview);
    promoSubtitleCtrl.removeListener(_bumpPreview);
    promoButtonTextCtrl.removeListener(_bumpPreview);
    promoImageUrlCtrl.removeListener(_bumpPreview);

    previewTick.dispose();

    codigoCtrl.dispose();
    nombreCtrl.dispose();
    descCtrl.dispose();
    precioCtrl.dispose();
    stockCtrl.dispose();
    descuentoCtrl.dispose();

    promoTitleCtrl.dispose();
    promoSubtitleCtrl.dispose();
    promoButtonTextCtrl.dispose();
    promoImageUrlCtrl.dispose();

    super.dispose();
  }
}
