import 'package:quimisol_web/features/productos/data/form_result.dart';

class DescuentoDraft {
  final String tipo; // "PORCENTAJE" | "MONTO"
  final double valor;

  const DescuentoDraft({required this.tipo, required this.valor});

  bool get isValid => valor > 0;
}

/// Resultado del diálogo:
/// - producto: datos del producto
/// - descuento: opcional (null si NO)
class ProductoDialogResult {
  final ProductoFormResult producto;
  final DescuentoDraft? descuento;

  const ProductoDialogResult({
    required this.producto,
    required this.descuento,
  });
}
