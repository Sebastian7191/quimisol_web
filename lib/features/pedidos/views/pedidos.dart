// lib/features/admin/pedidos/pedidos_page.dart

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quimisol_web/core/theme/palette.dart';
import 'package:quimisol_web/features/pedidos/views/detalle_pedido.dart';

// ✅ mismos estados canónicos
const String kEstadoPendiente = 'pendiente';
const String kEstadoAceptado = 'aceptado';
const String kEstadoEnCamino = 'en camino';
const String kEstadoEntregado = 'entregado';
const String kEstadoCancelado = 'cancelado';

String normalizeEstado(dynamic v) {
  final s = (v ?? '').toString().trim();
  if (s.isEmpty) return kEstadoPendiente;
  final low = s.toLowerCase().trim();
  if (low == 'aceptado' || s == 'Aceptado') return kEstadoAceptado;
  if (low == 'en camino' || low == 'encamino' || low == 'en_camino') return kEstadoEnCamino;
  if (low == 'pendiente') return kEstadoPendiente;
  if (low == 'entregado') return kEstadoEntregado;
  if (low == 'cancelado') return kEstadoCancelado;
  return low;
}

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _q = '';
  String _estado = 'Todos';

  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _searchCtrl.addListener(() {
      final v = _searchCtrl.text.trim();
      if (v == _q) return;
      setState(() => _q = v);
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _pedidosStream() {
    return FirebaseFirestore.instance
        .collection('pedidos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  bool _matches(Map<String, dynamic> p) {
    final estado = normalizeEstado(p['estado']);
    if (_estado != 'Todos' && estado != _estado) return false;

    if (_q.isEmpty) return true;
    final q = _q.toLowerCase();

    final codigo = (p['codigo'] ?? '').toString().toLowerCase();
    final direccion = (p['direccion'] ?? '').toString().toLowerCase();
    final uid = (p['uid'] ?? '').toString().toLowerCase();
    final depto = (p['departamento'] ?? '').toString().toLowerCase();

    return codigo.contains(q) || direccion.contains(q) || uid.contains(q) || depto.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    return Scaffold(
      backgroundColor: Palette.fieldBg,
      body: Column(
        children: [
          _PedidosHeader(
            bgCtrl: _bgCtrl,
            searchCtrl: _searchCtrl,
            estado: _estado,
            onEstado: (v) => setState(() => _estado = v),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _pedidosStream(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Error: ${snap.error}', style: TextStyle(color: ink)),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _LoadingFancy(text: 'Cargando pedidos…');
                }

                final docs = snap.data?.docs ?? [];
                final filtered = docs.where((d) => _matches(d.data())).toList();

                if (filtered.isEmpty) {
                  return _EmptyState(query: _q, estado: _estado);
                }

                final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byDepto = {};
                for (final d in filtered) {
                  final data = d.data();
                  final depto = (data['departamento'] ?? 'Sin departamento').toString().trim();
                  final key = depto.isEmpty ? 'Sin departamento' : depto;
                  (byDepto[key] ??= []).add(d);
                }

                final deptos = byDepto.keys.toList()
                  ..sort((a, b) {
                    if (a == 'Sin departamento') return 1;
                    if (b == 'Sin departamento') return -1;
                    return a.toLowerCase().compareTo(b.toLowerCase());
                  });

                final sections = <_DeptoSection>[];
                for (final depto in deptos) {
                  final list = byDepto[depto]!;
                  sections.add(_DeptoSection(departamento: depto, docs: list));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Row(
                        children: [
                          Text(
                            'Resultados',
                            style: TextStyle(
                              color: ink.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CountPill(count: filtered.length),
                          const Spacer(),
                          const _HintPill(text: 'Toca un pedido para ver detalle'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: sections.length,
                        itemBuilder: (_, i) {
                          final s = sections[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _DeptoBlock(
                              title: s.departamento,
                              count: s.docs.length,
                              children: List.generate(s.docs.length, (idx) {
                                final d = s.docs[idx];
                                final delay = math.min(420, (idx + i) * 18);
                                return _StaggerIn(
                                  delayMs: delay,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: idx == s.docs.length - 1 ? 0 : 10,
                                    ),
                                    child: _PedidoCard(
                                      doc: d,
                                      onTap: () async {
                                        final data = d.data();
                                        await showPedidoDetalleDialog(
                                          context,
                                          data,
                                          pedidoId: d.id,
                                        );
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= HEADER ================= */

class _PedidosHeader extends StatelessWidget {
  const _PedidosHeader({
    required this.bgCtrl,
    required this.searchCtrl,
    required this.estado,
    required this.onEstado,
  });

  final AnimationController bgCtrl;
  final TextEditingController searchCtrl;
  final String estado;
  final ValueChanged<String> onEstado;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    return AnimatedBuilder(
      animation: bgCtrl,
      builder: (_, __) {
        final t = bgCtrl.value;

        final left = Color.lerp(Palette.primary, Palette.gradientEnd, 0.20 + 0.25 * t)!;
        final mid = Color.lerp(Palette.gradientEnd, Palette.secondary, 0.18 + 0.25 * t)!;
        final right = Color.lerp(Palette.button, Palette.secondary, 0.22 + 0.25 * (1 - t))!;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [left, mid, right],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(26),
              bottomRight: Radius.circular(26),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pedidos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gestiona pedidos por departamento',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _EstadoFilterMini(value: estado, onChanged: onEstado),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Palette.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ink.withValues(alpha: 0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: ink.withValues(alpha: 0.45)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Buscar por código, dirección, uid o depto…',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: ink.withValues(alpha: 0.35),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: TextStyle(color: ink, fontWeight: FontWeight.w900),
                        ),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: searchCtrl,
                        builder: (_, v, __) {
                          final has = v.text.trim().isNotEmpty;
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                            child: !has
                                ? const SizedBox(width: 10, key: ValueKey('empty'))
                                : InkWell(
                                    key: const ValueKey('clear'),
                                    onTap: () => searchCtrl.clear(),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(Icons.close_rounded, color: ink.withValues(alpha: 0.55)),
                                    ),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EstadoFilterMini extends StatelessWidget {
  const _EstadoFilterMini({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    const items = <String>[
      'Todos',
      kEstadoPendiente,
      kEstadoAceptado,
      kEstadoEnCamino,
      kEstadoEntregado,
      kEstadoCancelado,
    ];

    String labelFor(String v) {
      switch (v) {
        case kEstadoPendiente:
          return 'Pendiente';
        case kEstadoAceptado:
          return 'Aceptado';
        case kEstadoEnCamino:
          return 'En camino';
        case kEstadoEntregado:
          return 'Entregado';
        case kEstadoCancelado:
          return 'Cancelado';
        default:
          return 'Todos';
      }
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: Palette.white,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5),
          onChanged: (v) => onChanged(v ?? 'Todos'),
          selectedItemBuilder: (_) => items.map((e) => Center(child: Text(labelFor(e)))).toList(),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(labelFor(e), style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

/* ================= SECCIONES POR DEPTO ================= */

class _DeptoSection {
  final String departamento;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  const _DeptoSection({required this.departamento, required this.docs});
}

class _DeptoBlock extends StatelessWidget {
  const _DeptoBlock({
    required this.title,
    required this.count,
    required this.children,
  });

  final String title;
  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    return Container(
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Palette.button.withValues(alpha: 0.26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.primary.withValues(alpha: 0.10)),
                ),
                child: const Icon(Icons.map_rounded, color: Palette.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Palette.fieldBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ink.withValues(alpha: 0.06)),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/* ================= CARD PEDIDO ================= */

class _PedidoCard extends StatelessWidget {
  const _PedidoCard({required this.doc, required this.onTap});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final ink = Palette.ink;

    final codigo = (data['codigo'] ?? '—').toString();
    final estado = normalizeEstado(data['estado']);

    final direccion = (data['direccion'] ?? '').toString();
    final depto = (data['departamento'] ?? '').toString();
    final conteo = (data['conteoItems'] is num) ? (data['conteoItems'] as num).toInt() : 0;

    final total = _asDouble(data['total']);
    final envio = _asDouble(data['costo_envio']);
    final totalFinal = total + envio;

    final fecha = _formatTs(data['createdAt']);
    final c = _statusColor(estado);

    return Material(
      color: Palette.fieldBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ink.withValues(alpha: 0.06)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 64,
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(999)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#$codigo',
                          style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 14.5),
                        ),
                        const SizedBox(width: 8),
                        _EstadoChip(estado: estado),
                        const Spacer(),
                        Text(
                          fecha.isEmpty ? '—' : fecha,
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      direccion.isEmpty ? '—' : direccion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.8,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _miniPill(Icons.map_rounded, depto.isEmpty ? '—' : depto),
                        _miniPill(Icons.shopping_bag_rounded, 'Items: $conteo'),
                        _miniPill(Icons.payments_rounded, _money(totalFinal)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: ink.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Palette.ink.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Palette.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Palette.ink.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (normalizeEstado(s)) {
      case kEstadoEntregado:
        return Palette.statsSuccess;
      case kEstadoCancelado:
        return Palette.statsDanger;
      case kEstadoEnCamino:
        return Palette.statsWarning;
      case kEstadoAceptado:
        return Palette.secondary;
      case kEstadoPendiente:
      default:
        return Palette.primary;
    }
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final st = normalizeEstado(estado);
    final c = _statusColor(st);
    final label = _label(st);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Palette.ink.withValues(alpha: 0.9),
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
        ),
      ),
    );
  }

  String _label(String s) {
    switch (normalizeEstado(s)) {
      case kEstadoEntregado:
        return 'Entregado';
      case kEstadoCancelado:
        return 'Cancelado';
      case kEstadoEnCamino:
        return 'En camino';
      case kEstadoAceptado:
        return 'Aceptado';
      case kEstadoPendiente:
      default:
        return 'Pendiente';
    }
  }

  Color _statusColor(String s) {
    switch (normalizeEstado(s)) {
      case kEstadoEntregado:
        return Palette.statsSuccess;
      case kEstadoCancelado:
        return Palette.statsDanger;
      case kEstadoEnCamino:
        return Palette.statsWarning;
      case kEstadoAceptado:
        return Palette.secondary;
      case kEstadoPendiente:
      default:
        return Palette.primary;
    }
  }
}

/* ================= MICRO UI / LOADING / EMPTY / STAGGER (IGUAL QUE TU CÓDIGO) ================= */

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Text(
        '$count',
        style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 12.5),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: ink.withValues(alpha: 0.55),
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _LoadingFancy extends StatelessWidget {
  const _LoadingFancy({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 34, width: 34, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(color: ink.withValues(alpha: 0.6), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.estado});
  final String query;
  final String estado;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ink.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 44, color: ink.withValues(alpha: 0.35)),
              const SizedBox(height: 10),
              Text(
                'Sin resultados',
                style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Estado: $estado${query.isEmpty ? '' : ' • "$query"'}',
                textAlign: TextAlign.center,
                style: TextStyle(color: ink.withValues(alpha: 0.55), fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaggerIn extends StatefulWidget {
  const _StaggerIn({required this.child, required this.delayMs});
  final Widget child;
  final int delayMs;

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_c);

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/* ================= HELPERS ================= */

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

String _money(double v) {
  final s = v.toStringAsFixed(2);
  return '$s Bs';
}

String _formatTs(dynamic ts) {
  try {
    if (ts is Timestamp) {
      final d = ts.toDate();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    }
  } catch (_) {}
  return '';
}
