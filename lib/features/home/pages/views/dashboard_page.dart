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
        .replaceAll('ñ', 'n');
    v = v.replaceAll('_', ' ');
    v = v.replaceAll(RegExp(r'\s+'), ' ');
    return v;
  }

  String _extractDep(Map<String, dynamic> m) {
    final raw = (m['departamento'] ??
            ((m['ubicacion'] is Map) ? (m['ubicacion']['departamento']) : null) ??
            '')
        .toString();
    return raw;
  }

  String _extractEstado(Map<String, dynamic> m) => (m['estado'] ?? '').toString();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filtrarPedidos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
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
                  DashboardHeader(width: w),
                  const SizedBox(height: 14),

                  // filtros (incluye almacenes desde Firestore)
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

                  const SizedBox(height: 14),

                  // Datos principales
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: repo.pedidosStream(from: from),
                    builder: (context, pedidosSnap) {
                      if (pedidosSnap.hasError) {
                        return _ErrorBox(
                          title: 'Error en pedidos (Firestore)',
                          error: pedidosSnap.error,
                          hint:
                              'Si el error menciona "index", crea el índice sugerido en Firebase Console.\n'
                              'Si menciona "permission-denied", revisa reglas/permisos.',
                        );
                      }

                      final pedidosAll = pedidosSnap.data?.docs ?? const [];
                      final pedidosDocs = _filtrarPedidos(pedidosAll);

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: repo.productosStream(almacenId: c.almacenId),
                        builder: (context, prodSnap) {
                          if (prodSnap.hasError) {
                            return _ErrorBox(
                              title: 'Error cargando productos',
                              error: prodSnap.error,
                            );
                          }
                          final prodDocs = prodSnap.data?.docs ?? const [];

                          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: repo.usuariosStream(),
                            builder: (context, userSnap) {
                              if (userSnap.hasError) {
                                return _ErrorBox(
                                  title: 'Error cargando usuarios',
                                  error: userSnap.error,
                                );
                              }
                              final userDocs = userSnap.data?.docs ?? const [];

                              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: repo.repartidoresStream(almacenId: c.almacenId),
                                builder: (context, repSnap) {
                                  if (repSnap.hasError) {
                                    return _ErrorBox(
                                      title: 'Error cargando repartidores',
                                      error: repSnap.error,
                                    );
                                  }
                                  final repDocs = repSnap.data?.docs ?? const [];

                                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                    stream: repo.bannersStream(),
                                    builder: (context, banSnap) {
                                      if (banSnap.hasError) {
                                        return _ErrorBox(
                                          title: 'Error cargando banners',
                                          error: banSnap.error,
                                        );
                                      }
                                      final banDocs = banSnap.data?.docs ?? const [];

                                      final stats = DashboardStats.build(
                                        pedidos: pedidosDocs,
                                        productos: prodDocs,
                                        usuarios: userDocs,
                                        repartidores: repDocs,
                                        banners: banDocs,
                                        rangeStart: from,
                                      );

                                      return Column(
                                        children: [
                                          DashboardStatCards(width: w, stats: stats),
                                          const SizedBox(height: 14),
                                          DashboardSections(width: w, stats: stats, range: c.range),
                                          const SizedBox(height: 22),

                                          if (c.range == DashboardRange.all)
                                            _InfoBox(
                                              text:
                                                  'Nota: "Todo" está limitado a los últimos pedidos por performance.\n'
                                                  'Si necesitas reportes históricos completos, conviene hacer agregaciones (Cloud Functions / BigQuery).',
                                            ),
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

                  const SizedBox(height: 22),
                  Text(
                    'Tip: si algún gráfico sale vacío, revisa el rango/filtros.',
                    style: TextStyle(
                      color: Palette.ink.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({
    required this.title,
    required this.error,
    this.hint,
  });

  final String title;
  final Object? error;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text((error ?? 'Error desconocido').toString(),
              style: TextStyle(color: Palette.ink.withValues(alpha: 0.85))),
          if (hint != null) ...[
            const SizedBox(height: 10),
            Text(hint!, style: TextStyle(color: Palette.ink.withValues(alpha: 0.7))),
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Palette.ink.withValues(alpha: 0.78),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
