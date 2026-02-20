import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';

import '../controllers/dashboard_controller.dart';
import '../data/dashboard_firestore.dart';
import '../data/dashboard_models.dart';

import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_filters.dart';
import 'widgets/dashboard_stat_cards.dart';
import 'widgets/dashboard_sections.dart';

// 🔥 Importación del servicio de exportación (Excel / PDF)
import '../services/export_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController c;
  late final DashboardFirestore repo;

  @override
  void initState() {
    super.initState();
    c = DashboardController();
    repo = DashboardFirestore(FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  String _norm(String s) {
    var v = s.trim().toLowerCase();
    v = v
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('_', ' ');
    v = v.replaceAll(RegExp(r'\s+'), ' ');
    return v;
  }

  String _extractDep(Map<String, dynamic> m) {
    final raw = (m['departamento'] ??
            (m['ubicacion'] is Map ? (m['ubicacion']['departamento']) : null) ??
            '')
        .toString();
    return raw;
  }

  String _extractEstado(Map<String, dynamic> m) =>
      (m['estado'] ?? '').toString();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filtrarPedidos(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final depFiltro = c.departamento;
    final estFiltro = c.estado;

    if (depFiltro == null && estFiltro == null) return docs;

    final depN = depFiltro == null ? null : _norm(depFiltro);
    final estN = estFiltro == null ? null : _norm(estFiltro);

    return docs.where((d) {
      final m = d.data();

      if (depN != null) {
        final dep = _norm(_extractDep(m));
        if (dep != depN) return false;
      }

      if (estN != null) {
        final est = _norm(_extractEstado(m));
        if (est != estN) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final from = c.rangeStart;

        return LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================================
                  // STREAM ALMACENES
                  // ================================
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: repo.almacenesStream(),
                    builder: (context, snapAlm) {
                      if (snapAlm.hasError) {
                        return _ErrorBox(
                          title: 'Error cargando almacenes',
                          error: snapAlm.error,
                        );
                      }
                      final almacenes = snapAlm.data?.docs ?? const [];

                      return DashboardFilters(
                        controller: c,
                        almacenes: almacenes,
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // ================================
                  // STREAM PEDIDOS
                  // ================================
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: repo.pedidosStream(from: from),
                    builder: (context, pedidosSnap) {
                      if (pedidosSnap.hasError) {
                        return _ErrorBox(
                          title: 'Error cargando pedidos',
                          error: pedidosSnap.error,
                        );
                      }

                      final pedidosAll = pedidosSnap.data?.docs ?? const [];
                      final pedidosDocs = _filtrarPedidos(pedidosAll);

                      // ================================
                      // STREAM PRODUCTOS
                      // ================================
                      return StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                        stream:
                            repo.productosStream(almacenId: c.almacenId),
                        builder: (context, prodSnap) {
                          if (prodSnap.hasError) {
                            return _ErrorBox(
                              title: 'Error cargando productos',
                              error: prodSnap.error,
                            );
                          }

                          final prodDocs =
                              prodSnap.data?.docs ?? const [];

                          // ================================
                          // STREAM USUARIOS
                          // ================================
                          return StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                            stream: repo.usuariosStream(),
                            builder: (context, userSnap) {
                              if (userSnap.hasError) {
                                return _ErrorBox(
                                  title: 'Error cargando usuarios',
                                  error: userSnap.error,
                                );
                              }

                              final userDocs =
                                  userSnap.data?.docs ?? const [];

                              // ================================
                              // STREAM REPARTIDORES
                              // ================================
                              return StreamBuilder<
                                      QuerySnapshot<Map<String, dynamic>>>(
                                stream: repo.repartidoresStream(
                                    almacenId: c.almacenId),
                                builder: (context, repSnap) {
                                  if (repSnap.hasError) {
                                    return _ErrorBox(
                                      title:
                                          'Error cargando repartidores',
                                      error: repSnap.error,
                                    );
                                  }

                                  final repDocs =
                                      repSnap.data?.docs ?? const [];

                                  // ================================
                                  // STREAM BANNERS
                                  // ================================
                                  return StreamBuilder<
                                          QuerySnapshot<
                                              Map<String, dynamic>>>(
                                    stream: repo.bannersStream(),
                                    builder: (context, banSnap) {
                                      if (banSnap.hasError) {
                                        return _ErrorBox(
                                          title:
                                              'Error cargando banners',
                                          error: banSnap.error,
                                        );
                                      }

                                      final banDocs =
                                          banSnap.data?.docs ??
                                              const [];

                                      // ================================
                                      // CREAR MODELO COMPLETO
                                      // ================================
                                      final stats =
                                          DashboardStats.build(
                                        pedidos: pedidosDocs,
                                        productos: prodDocs,
                                        usuarios: userDocs,
                                        repartidores: repDocs,
                                        banners: banDocs,
                                        rangeStart: from,
                                        almacenId: c.almacenId,
                                      );

                                      // ================================
                                      // UI FINAL
                                      // ================================
                                      return Column(
                                        children: [
                                          DashboardHeader(
                                            width: w,
                                            onExportExcel: () =>
                                                ExportService
                                                    .exportAllExcel(stats),
                                            onExportPdf: () =>
                                                ExportService
                                                    .exportAllPDF(stats),
                                          ),

                                          const SizedBox(height: 14),

                                          DashboardStatCards(
                                              width: w, stats: stats),
                                          const SizedBox(height: 14),

                                          DashboardSections(
                                            width: w,
                                            stats: stats,
                                            range: c.range,
                                          ),

                                          const SizedBox(height: 22),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
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

// ======================================================
// COMPONENTES DE ERROR E INFO
// ======================================================

class _ErrorBox extends StatelessWidget {
  final String title;
  final Object? error;
  final String? hint;

  const _ErrorBox({
    required this.title,
    required this.error,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: Colors.red)),
          const SizedBox(height: 8),
          Text(error.toString(),
              style: TextStyle(
                color: Palette.ink.withOpacity(0.85),
              )),
          if (hint != null) ...[
            const SizedBox(height: 10),
            Text(
              hint!,
              style:
                  TextStyle(color: Palette.ink.withOpacity(0.7)),
            ),
          ]
        ],
      ),
    );
  }
}
