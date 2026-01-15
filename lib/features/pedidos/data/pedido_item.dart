class PedidoItemData {
  final String nombre;
  final String imageUrl;
  final int cantidad;
  final double precio;

  double get subtotal => cantidad * precio;

  PedidoItemData({
    required this.nombre,
    required this.imageUrl,
    required this.cantidad,
    required this.precio,
  });

  factory PedidoItemData.fromMap(Map<String, dynamic> m) {
    return PedidoItemData(
      nombre: (m['name'] ?? m['nombre'] ?? '—').toString(),
      imageUrl: (m['imageUrl'] ?? '').toString(),
      cantidad: _asInt(m['qty'], fallback: 1),
      precio: _asDouble(m['price']),
    );
  }
}

/* ===================== HELPERS ===================== */

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}