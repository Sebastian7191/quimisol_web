import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../data/producto_row.dart';
import '../data/form_result.dart';

class ProductosController {
  final _db = FirebaseFirestore.instance;

  final FirebaseStorage storage = FirebaseStorage.instanceFor(
    bucket: 'gs://quimisol-4f159.firebasestorage.app',
  );

  CollectionReference<Map<String, dynamic>> get productosRef =>
      _db.collection('productos');

  CollectionReference<Map<String, dynamic>> get unidadesRef =>
      _db.collection('unidades');

  CollectionReference<Map<String, dynamic>> get almacenesRef =>
      _db.collection('almacenes');

  Stream<QuerySnapshot<Map<String, dynamic>>> productosStream() =>
      productosRef.snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> unidadesStream() =>
      unidadesRef.snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> almacenesStream() =>
      almacenesRef.snapshots();

  ProductoRow mapProducto(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? {};

    final ts = data['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : null;

    final precioRaw = data['precio'];
    final precio = (precioRaw is num) ? precioRaw.toDouble() : 0.0;

    final stockRaw = data['stock'];
    final stock = (stockRaw is num) ? stockRaw.toInt() : 0;

    return ProductoRow(
      id: d.id,
      codigo: (data['codigo'] ?? '').toString(),
      nombre: (data['nombre'] ?? '').toString(),
      tipoItem: (data['tipoItem'] ?? 'PRODUCTO').toString(),
      unidadId: (data['unidadId'] ?? '').toString(),
      unidadNombre: (data['unidadNombre'] ?? '').toString(),
      descripcion: (data['descripcion'] ?? '').toString(),
      precio: precio,
      stock: stock,
      createdAt: createdAt,
      imagenUrl: (data['imagenUrl'] ?? '').toString(),
      imagenPath: (data['imagenPath'] ?? '').toString(),
      almacenId: (data['almacenId'] ?? '').toString(),
      almacenNombre: (data['almacenNombre'] ?? '').toString(),
    );
  }

  List<ProductoRow> filterProductos({
    required List<ProductoRow> rows,
    required String search,
    required String tipo,
  }) {
    final q = search.trim().toLowerCase();

    final byTipo = tipo == 'Todos'
        ? rows
        : rows.where((r) => r.tipoItem == tipo).toList();

    if (q.isEmpty) return byTipo;

    return byTipo.where((r) {
      return r.codigo.toLowerCase().contains(q) ||
          r.nombre.toLowerCase().contains(q);
    }).toList();
  }

  String sanitizeFilename(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'\s+'), '_');
    if (cleaned.isEmpty) return 'imagen.png';
    return cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
  }

  String guessExtFromBytes(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    return 'png';
  }

  Future<Map<String, String>> uploadImage({
    required String productId,
    required Uint8List bytes,
    String? filename,
  }) async {
    final ext = guessExtFromBytes(bytes);
    final safeName = sanitizeFilename(filename ?? 'imagen.$ext');
    final path = 'productos_e_insumos/$productId/$safeName';

    final ref = storage.ref().child(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
    final url = await ref.getDownloadURL();

    return {'url': url, 'path': path};
  }

  Future<void> deleteImage(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    try {
      await storage.ref().child(path).delete();
    } catch (_) {}
  }

  Future<void> crearProducto(ProductoFormResult r) async {
    final doc = productosRef.doc();
    final id = doc.id;

    String url = '';
    String path = '';

    if (r.imageBytes != null) {
      final up = await uploadImage(
        productId: id,
        bytes: r.imageBytes!,
        filename: r.imageName,
      );
      url = up['url']!;
      path = up['path']!;
    }

    await doc.set({
      'codigo': r.codigo.trim(),
      'nombre': r.nombre.trim(),
      'descripcion': r.descripcion.trim(),
      'tipoItem': r.tipoItem,
      'unidadId': r.unidadId,
      'unidadNombre': r.unidadNombre,
      'precio': r.precio,
      'stock': r.stock,
      'imagenUrl': url,
      'imagenPath': path,
      'almacenId': r.almacenId,
      'almacenNombre': r.almacenNombre,
      'activo': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> actualizarProducto(
    String id,
    ProductoFormResult r, {
    String? existingImagenUrl,
    String? existingImagenPath,
  }) async {
    String url = existingImagenUrl ?? '';
    String path = existingImagenPath ?? '';

    if (r.imageBytes != null) {
      if (path.trim().isNotEmpty) {
        await deleteImage(path);
      }
      final up = await uploadImage(
        productId: id,
        bytes: r.imageBytes!,
        filename: r.imageName,
      );
      url = up['url']!;
      path = up['path']!;
    }

    await productosRef.doc(id).update({
      'codigo': r.codigo.trim(),
      'nombre': r.nombre.trim(),
      'descripcion': r.descripcion.trim(),
      'tipoItem': r.tipoItem,
      'unidadId': r.unidadId,
      'unidadNombre': r.unidadNombre,
      'precio': r.precio,
      'stock': r.stock,
      'imagenUrl': url,
      'imagenPath': path,
      'almacenId': r.almacenId,
      'almacenNombre': r.almacenNombre,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminarProducto(String id, String? imagenPath) async {
    await productosRef.doc(id).delete();
    await deleteImage(imagenPath);
  }
}
