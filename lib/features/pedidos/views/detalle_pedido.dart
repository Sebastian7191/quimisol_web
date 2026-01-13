// lib/features/admin/pedidos/detalle_pedido.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quimisol_web/core/theme/palette.dart';

Future<void> showPedidoDetalleDialog(
  BuildContext context,
  Map<String, dynamic> pedido, {
  String? pedidoId,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _PedidoDetalleDialog(pedido: pedido, pedidoId: pedidoId),
  );
}

/* ===================== ESTADOS (CANÓNICOS) ===================== */
const String kEstadoPendiente = 'pendiente';
const String kEstadoAceptado = 'aceptado';
const String kEstadoEnCamino = 'en camino';
const String kEstadoEntregado = 'entregado';
const String kEstadoCancelado = 'cancelado';

String normalizeEstado(dynamic v) {
  final s = (v ?? '').toString().trim();
  if (s.isEmpty) return kEstadoPendiente;
  final low = s.toLowerCase().trim();

  // Compatibilidad con valores viejos o variantes
  if (low == 'aceptado' || s == 'Aceptado') return kEstadoAceptado;
  if (low == 'en camino' || low == 'encamino' || low == 'en_camino') {
    return kEstadoEnCamino;
  }
  if (low == 'pendiente') return kEstadoPendiente;
  if (low == 'entregado') return kEstadoEntregado;
  if (low == 'cancelado') return kEstadoCancelado;

  return low; // fallback: conserva algo raro pero consistente
}

class _PedidoDetalleDialog extends StatefulWidget {
  const _PedidoDetalleDialog({required this.pedido, this.pedidoId});

  final Map<String, dynamic> pedido;
  final String? pedidoId;

  @override
  State<_PedidoDetalleDialog> createState() => _PedidoDetalleDialogState();
}

class _PedidoDetalleDialogState extends State<_PedidoDetalleDialog> {
  bool _saving = false;

  // edición
  String? _estadoEdit;
  DateTime? _fechaEnvioEdit;
  double? _costoEnvioEdit;

  // asignación
  String? _repartidorUidEdit;

  late final TextEditingController _costoCtrl;

  DocumentReference<Map<String, dynamic>>? get _pedidoRef {
    final id = widget.pedidoId;
    if (id == null || id.trim().isEmpty) return null;
    return FirebaseFirestore.instance.collection('pedidos').doc(id);
  }

  String get _codigo => (widget.pedido['codigo'] ?? '—').toString();

  String get _estado => normalizeEstado(widget.pedido['estado']);

  String get _uidCliente => (widget.pedido['uid'] ?? '').toString().trim();

  Map<String, dynamic> get _ubic {
    final u = widget.pedido['ubicacion'];
    if (u is Map<String, dynamic>) return u;
    if (u is Map) return Map<String, dynamic>.from(u);
    return <String, dynamic>{};
  }

  String get _direccionPedido =>
      (widget.pedido['direccion'] ?? '').toString().trim();

  String get _deptoPedido =>
      (widget.pedido['departamento'] ?? _ubic['departamento'] ?? '')
          .toString()
          .trim();

  // ✅ almacenId del pedido (si existe)
  String get _almacenIdPedido {
    final v =
        widget.pedido['almacenId'] ??
        widget.pedido['almacen_id'] ??
        widget.pedido['almacenUid'] ??
        widget.pedido['almacen_uid'];
    return (v ?? '').toString().trim();
  }

  @override
  void initState() {
    super.initState();

    _estadoEdit = _estado;

    final fe = widget.pedido['fecha_envio'] ?? widget.pedido['fechaEnvio'];
    if (fe is Timestamp) _fechaEnvioEdit = fe.toDate();
    if (fe is DateTime) _fechaEnvioEdit = fe;

    final repUid =
        widget.pedido['repartidorUid'] ?? widget.pedido['repartidor_uid'];
    final rep = (repUid ?? '').toString().trim();
    _repartidorUidEdit = rep.isEmpty ? null : rep;

    final costo = _asDouble(widget.pedido['costo_envio']);
    _costoEnvioEdit = costo;
    _costoCtrl = TextEditingController(text: _moneyNoSuffix(costo));
  }

  @override
  void dispose() {
    _costoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFechaEnvio() async {
    final now = DateTime.now();
    final initial = _fechaEnvioEdit ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Palette.primary,
              primary: Palette.primary,
              secondary: Palette.button,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;
    if (!mounted) return; // ✅ evita warning async gap

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Palette.primary,
              primary: Palette.primary,
              secondary: Palette.button,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? initial.hour,
      time?.minute ?? initial.minute,
    );

    setState(() => _fechaEnvioEdit = picked);
  }

  void _applyCostoFromText() {
    final raw = _costoCtrl.text.trim();
    final v = _parseMoney(raw);
    setState(() => _costoEnvioEdit = v < 0 ? 0 : v);
  }

  Future<void> _saveChanges() async {
    if (_pedidoRef == null) {
      _snack('No se puede guardar: falta pedidoId.');
      return;
    }

    _applyCostoFromText();

    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{};

      // ✅ Estado: solo permitir pendiente -> aceptado
      final nuevoEstado = normalizeEstado(_estadoEdit ?? _estado);
      if (_estado == kEstadoPendiente && nuevoEstado == kEstadoAceptado) {
        updates['estado'] = kEstadoAceptado;
      }

      // Fecha envío
      updates['fecha_envio'] =
          _fechaEnvioEdit == null ? null : Timestamp.fromDate(_fechaEnvioEdit!);

      // Costo envío
      updates['costo_envio'] = (_costoEnvioEdit ?? 0);

      // Repartidor
      if (_repartidorUidEdit != null && _repartidorUidEdit!.isNotEmpty) {
        updates['repartidorUid'] = _repartidorUidEdit;
      } else {
        updates['repartidorUid'] = FieldValue.delete();
        updates['repartidorNombre'] = FieldValue.delete();
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _pedidoRef!.update(updates);

      // Guardar nombre del repartidor
      if (_repartidorUidEdit != null && _repartidorUidEdit!.isNotEmpty) {
        final repSnap = await FirebaseFirestore.instance
            .collection('repartidores')
            .doc(_repartidorUidEdit)
            .get();
        final rep = repSnap.data() ?? {};
        final repName = (rep['name'] ?? rep['nombre'] ?? 'Repartidor').toString();
        await _pedidoRef!.update({'repartidorNombre': repName});
      }

      if (!mounted) return;
      _snack('Pedido actualizado ✅');
      Navigator.pop(context);
    } catch (e) {
      _snack('No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final total = _asDouble(widget.pedido['total']);
    final costoEnvio = _costoEnvioEdit ?? _asDouble(widget.pedido['costo_envio']);
    final totalFinal = total + costoEnvio;

    final createdText = _formatTs(widget.pedido['createdAt']);

    final ubNombre = (_ubic['nombre'] ?? '').toString();
    final ubDireccion = (_ubic['direccion'] ?? '').toString();

    final direccionFinal =
        _direccionPedido.isNotEmpty ? _direccionPedido : ubDireccion;

    final itemsRaw =
        (widget.pedido['items'] is List) ? (widget.pedido['items'] as List) : [];
    final items = itemsRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: Palette.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ===== HEADER =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Palette.primary.withValues(alpha: 0.96),
                          Palette.secondary.withValues(alpha: 0.92),
                          Palette.button.withValues(alpha: 0.96),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                            ),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pedido #$_codigo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                createdText.isEmpty ? '—' : 'Creado: $createdText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _EstadoPill(estado: _estado),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ===== BODY =====
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, c) {
                              final isWide = c.maxWidth >= 780;

                              final left = _SectionCard(
                                title: 'Entrega',
                                icon: Icons.location_on_rounded,
                                child: _EntregaInfo(
                                  ubNombre: ubNombre,
                                  direccion: direccionFinal,
                                  departamento: _deptoPedido,
                                ),
                              );

                              final right = _SectionCard(
                                title: 'Cliente',
                                icon: Icons.person_rounded,
                                child: _ClienteInfo(
                                  uid: _uidCliente,
                                  codigoPedido: _codigo,
                                  conteo:
                                      (widget.pedido['conteoItems'] ?? items.length)
                                          .toString(),
                                ),
                              );

                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 6, child: left),
                                    const SizedBox(width: 14),
                                    Expanded(flex: 4, child: right),
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  left,
                                  const SizedBox(height: 14),
                                  right,
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 14),

                          // ===== GESTIÓN =====
                          _SectionCard(
                            title: 'Gestión',
                            icon: Icons.tune_rounded,
                            child: Column(
                              children: [
                                _EditRow(
                                  label: 'Estado',
                                  child: _EstadoEditor(
                                    estadoActual: _estado,
                                    value: normalizeEstado(_estadoEdit ?? _estado),
                                    onChanged: _saving
                                        ? null
                                        : (v) => setState(() => _estadoEdit = v),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                _EditRow(
                                  label: 'Fecha envío',
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Palette.fieldBg,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Palette.ink.withValues(alpha: 0.06),
                                            ),
                                          ),
                                          child: Text(
                                            _fechaEnvioEdit == null
                                                ? '—'
                                                : DateFormat('dd/MM/yyyy HH:mm', 'es_BO')
                                                    .format(_fechaEnvioEdit!),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Palette.ink,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      OutlinedButton.icon(
                                        onPressed: _saving ? null : _pickFechaEnvio,
                                        icon: const Icon(Icons.calendar_month_rounded),
                                        label: const Text('Editar'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Palette.primary,
                                          side: BorderSide(
                                            color: Palette.primary.withValues(alpha: 0.30),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                _EditRow(
                                  label: 'Costo envío',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Palette.fieldBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Palette.ink.withValues(alpha: 0.06),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.local_shipping_rounded,
                                          size: 18,
                                          color: Palette.primary.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _costoCtrl,
                                            enabled: !_saving,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                              decimal: true,
                                              signed: false,
                                            ),
                                            onChanged: (_) => _applyCostoFromText(),
                                            decoration: InputDecoration(
                                              hintText: '0.00',
                                              border: InputBorder.none,
                                              isDense: true,
                                              hintStyle: TextStyle(
                                                color: Palette.ink.withValues(alpha: 0.45),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: Palette.ink,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Palette.button.withValues(alpha: 0.28),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Palette.primary.withValues(alpha: 0.10),
                                            ),
                                          ),
                                          child: Text(
                                            'Bs',
                                            style: TextStyle(
                                              color: Palette.ink.withValues(alpha: 0.85),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                _EditRow(
                                  label: 'Repartidor',
                                  child: _RepartidorPicker(
                                    enabled: !_saving,
                                    departamentoPedido: _deptoPedido,
                                    pedidoAlmacenId: _almacenIdPedido,
                                    valueUid: _repartidorUidEdit,
                                    onChanged: (uid) =>
                                        setState(() => _repartidorUidEdit = uid),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          _SectionCard(
                            title: 'Productos',
                            icon: Icons.shopping_bag_rounded,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Palette.button.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Palette.primary.withValues(alpha: 0.16),
                                ),
                              ),
                              child: Text(
                                '${items.length}',
                                style: TextStyle(
                                  color: Palette.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            child: items.isEmpty
                                ? const _EmptyBox(text: 'No hay items en este pedido.')
                                : Column(
                                    children: [
                                      for (int i = 0; i < items.length; i++)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: i == items.length - 1 ? 0 : 10,
                                          ),
                                          child: _ItemTile(item: items[i]),
                                        ),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: 14),

                          _SectionCard(
                            title: 'Totales',
                            icon: Icons.calculate_rounded,
                            child: _KeyValueList(
                              rows: [
                                _KV('Total productos', _money(total)),
                                _KV('Costo envío', _money(costoEnvio)),
                                _KV('Total final', _money(totalFinal), isStrong: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ===== FOOTER =====
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                    decoration: BoxDecoration(
                      color: Palette.fieldBg,
                      border: Border(
                        top: BorderSide(color: Palette.ink.withValues(alpha: 0.06)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tip: asigna repartidor y fecha de envío antes de confirmar.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Palette.ink.withValues(alpha: 0.62),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Palette.primary,
                            side: BorderSide(color: Palette.primary.withValues(alpha: 0.25)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Cerrar'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _saving ? null : _saveChanges,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Palette.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== SECCIONES ===================== */

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    return Container(
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
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
                child: Icon(icon, color: Palette.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EntregaInfo extends StatelessWidget {
  const _EntregaInfo({
    required this.ubNombre,
    required this.direccion,
    required this.departamento,
  });

  final String ubNombre;
  final String direccion;
  final String departamento;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    Widget pill(String text, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Palette.fieldBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ink.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Palette.primary),
              const SizedBox(width: 6),
            ],
            Text(
              text.isEmpty ? '—' : text,
              style: TextStyle(
                color: ink.withValues(alpha: 0.78),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (direccion.isEmpty)
          const _EmptyBox(text: 'No se registró dirección.')
        else
          Text(
            direccion,
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
              height: 1.25,
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            pill(departamento.isEmpty ? '—' : departamento, icon: Icons.map_rounded),
            if (ubNombre.isNotEmpty) pill(ubNombre, icon: Icons.home_rounded),
          ],
        ),
      ],
    );
  }
}

class _ClienteInfo extends StatelessWidget {
  const _ClienteInfo({
    required this.uid,
    required this.codigoPedido,
    required this.conteo,
  });

  final String uid;
  final String codigoPedido;
  final String conteo;

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return _KeyValueList(
        rows: [
          const _KV('Nombre', '—'),
          const _KV('Email', '—'),
          _KV('Pedido', codigoPedido.isEmpty ? '—' : '#$codigoPedido', isStrong: true),
          _KV('Conteo Productos', conteo),
        ],
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
      builder: (context, snap) {
        String nombre = '—';
        String email = '—';

        if (snap.connectionState == ConnectionState.waiting) {
          nombre = 'Cargando…';
          email = '…';
        } else if (snap.hasData && snap.data?.data() != null) {
          final u = snap.data!.data()!;
          nombre = (u['name'] ?? u['nombre'] ?? 'Cliente').toString();
          email = (u['email'] ?? '—').toString();
        }

        return _KeyValueList(
          rows: [
            _KV('Nombre', nombre),
            _KV('Email', email),
            _KV('Pedido', codigoPedido.isEmpty ? '—' : '#$codigoPedido', isStrong: true),
            _KV('Conteo Productos', conteo),
          ],
        );
      },
    );
  }
}

/* ===================== GESTIÓN ===================== */

class _EditRow extends StatelessWidget {
  const _EditRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              label,
              style: TextStyle(
                color: ink.withValues(alpha: 0.62),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

class _EstadoEditor extends StatelessWidget {
  const _EstadoEditor({
    required this.estadoActual,
    required this.value,
    required this.onChanged,
  });

  final String estadoActual;
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    final options = <String>[
      normalizeEstado(estadoActual),
      if (normalizeEstado(estadoActual) == kEstadoPendiente) kEstadoAceptado,
    ].toSet().toList();

    String label(String v) {
      switch (normalizeEstado(v)) {
        case kEstadoAceptado:
          return 'Aceptado';
        case kEstadoPendiente:
          return 'Pendiente';
        case kEstadoEnCamino:
          return 'En camino';
        case kEstadoEntregado:
          return 'Entregado';
        case kEstadoCancelado:
          return 'Cancelado';
        default:
          return v;
      }
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Palette.fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Palette.white,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: ink.withValues(alpha: 0.55)),
          style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 12.8),
          onChanged: onChanged == null ? null : (v) => onChanged!(v ?? value),
          items: options
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(label(e))))
              .toList(growable: false),
        ),
      ),
    );
  }
}

/* ===================== REPARTIDOR PICKER (igual que tu lógica) ===================== */

class _RepartidorPicker extends StatelessWidget {
  const _RepartidorPicker({
    required this.enabled,
    required this.departamentoPedido,
    required this.pedidoAlmacenId,
    required this.valueUid,
    required this.onChanged,
  });

  final bool enabled;
  final String departamentoPedido;
  final String pedidoAlmacenId;
  final String? valueUid;
  final ValueChanged<String?> onChanged;

  Future<List<String>> _almacenesIdsPermitidos() async {
    if (pedidoAlmacenId.trim().isNotEmpty) return [pedidoAlmacenId.trim()];

    final depto = departamentoPedido.trim();
    if (depto.isEmpty) return [];

    final q = await FirebaseFirestore.instance
        .collection('almacenes')
        .where('departamento', isEqualTo: depto)
        .where('activo', isEqualTo: true)
        .limit(10)
        .get();

    return q.docs.map((d) => d.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    if (departamentoPedido.trim().isEmpty && pedidoAlmacenId.trim().isEmpty) {
      return const _WarnBox(
        text:
            'Este pedido no tiene "departamento" ni "almacenId". No se puede filtrar repartidores.',
      );
    }

    return FutureBuilder<List<String>>(
      future: _almacenesIdsPermitidos(),
      builder: (context, snapIds) {
        if (snapIds.connectionState == ConnectionState.waiting) {
          return _ghostField('Cargando almacenes…', ink);
        }
        if (snapIds.hasError) {
          return _WarnBox(text: 'Error obteniendo almacenes: ${snapIds.error}');
        }

        final ids = snapIds.data ?? [];
        if (ids.isEmpty) {
          return _WarnBox(
            text: 'No se encontraron almacenes activos para "$departamentoPedido".',
          );
        }

        final Query<Map<String, dynamic>> repQuery = (ids.length == 1)
            ? FirebaseFirestore.instance
                .collection('repartidores')
                .where('almacenId', isEqualTo: ids.first)
            : FirebaseFirestore.instance
                .collection('repartidores')
                .where('almacenId', whereIn: ids);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: repQuery.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _ghostField('Cargando repartidores…', ink);
            }
            if (snap.hasError) {
              return _WarnBox(text: 'Error cargando repartidores: ${snap.error}');
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              final extra = pedidoAlmacenId.trim().isNotEmpty
                  ? 'del almacén del pedido'
                  : 'de almacenes en "$departamentoPedido"';
              return _WarnBox(text: 'No hay repartidores $extra.');
            }

            final exists = valueUid != null && docs.any((d) => d.id == valueUid);
            final current = exists ? valueUid : null;

            return Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Palette.fieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ink.withValues(alpha: 0.06)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: current,
                  isExpanded: true,
                  dropdownColor: Palette.white,
                  borderRadius: BorderRadius.circular(14),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: ink.withValues(alpha: 0.55)),
                  style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 12.8),
                  onChanged: enabled ? (v) => onChanged(v) : null,
                  hint: Text(
                    'Seleccionar repartidor…',
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('— Sin asignar —'),
                    ),
                    ...docs.map((d) {
                      final r = d.data();
                      final name = (r['name'] ?? r['nombre'] ?? 'Repartidor').toString();
                      return DropdownMenuItem<String?>(
                        value: d.id,
                        child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _ghostField(String text, Color ink) {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Palette.fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: ink.withValues(alpha: 0.7),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/* ===================== ITEMS / UI / HELPERS (TU MISMO CÓDIGO) ===================== */

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    final name = (item['name'] ?? '—').toString();
    final imageUrl = (item['imageUrl'] ?? '').toString();
    final qty = _asInt(item['qty'], fallback: 1);
    final price = _asDouble(item['price']);
    final subtotal = qty * price;

    return Container(
      decoration: BoxDecoration(
        color: Palette.fieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          _Thumb(url: imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _miniPill('Cantidad: $qty'),
                    _miniPill('Precio: ${_money(price)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Palette.button.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Palette.primary.withValues(alpha: 0.10)),
            ),
            child: Text(
              _money(subtotal),
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Palette.ink.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Palette.ink.withValues(alpha: 0.72),
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ink.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: url.isEmpty
            ? Icon(Icons.image_not_supported_rounded, color: Palette.primary.withValues(alpha: 0.6))
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image_rounded,
                  color: Palette.primary.withValues(alpha: 0.6),
                ),
              ),
      ),
    );
  }
}

class _KeyValueList extends StatelessWidget {
  const _KeyValueList({required this.rows});
  final List<_KV> rows;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Palette.fieldBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ink.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    rows[i].k,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Text(
                    rows[i].v,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontWeight: rows[i].isStrong ? FontWeight.w900 : FontWeight.w800,
                      fontSize: rows[i].isStrong ? 13.5 : 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (i != rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.fieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: ink.withValues(alpha: 0.55)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ink.withValues(alpha: 0.70),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarnBox extends StatelessWidget {
  const _WarnBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.button.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: ink.withValues(alpha: 0.75)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ink.withValues(alpha: 0.78),
                fontWeight: FontWeight.w800,
                fontSize: 12.2,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== ESTADO CHIP HEADER ===================== */

class _EstadoPill extends StatelessWidget {
  const _EstadoPill({required this.estado});
  final String estado;

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

  @override
  Widget build(BuildContext context) {
    final st = normalizeEstado(estado);
    final c = _statusColor(st);
    final label = _label(st);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(st), size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              shadows: [
                Shadow(blurRadius: 10, color: Colors.black.withValues(alpha: 0.12)),
              ],
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

  IconData _statusIcon(String s) {
    switch (normalizeEstado(s)) {
      case kEstadoEntregado:
        return Icons.check_circle_rounded;
      case kEstadoCancelado:
        return Icons.cancel_rounded;
      case kEstadoEnCamino:
        return Icons.local_shipping_rounded;
      case kEstadoAceptado:
        return Icons.verified_rounded;
      case kEstadoPendiente:
      default:
        return Icons.schedule_rounded;
    }
  }
}

/* ===================== HELPERS ===================== */

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

String _money(double v) {
  final f = NumberFormat('#,##0.00', 'es_BO');
  return '${f.format(v)} Bs';
}

String _moneyNoSuffix(double v) {
  final f = NumberFormat('#,##0.00', 'es_BO');
  return f.format(v);
}

double _parseMoney(String raw) {
  final s = raw
      .replaceAll('Bs', '')
      .replaceAll('bs', '')
      .replaceAll(' ', '')
      .trim();
  if (s.isEmpty) return 0;
  if (s.contains(',') && s.contains('.')) {
    final normalized = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }
  if (s.contains(',') && !s.contains('.')) {
    return double.tryParse(s.replaceAll(',', '.')) ?? 0;
  }
  return double.tryParse(s) ?? 0;
}

String _formatTs(dynamic ts) {
  try {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(d);
    }
    return ts.toString();
  } catch (_) {
    return '';
  }
}

class _KV {
  final String k;
  final String v;
  final bool isStrong;
  const _KV(this.k, this.v, {this.isStrong = false});
}
