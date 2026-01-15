// lib/features/admin/pedidos/detalle_pedido.dart
//
// ✅ Modal / Ventana emergente bonita para ver detalle de un pedido
// ✅ Visual pro (paleta rosa/morado), organizada por secciones
// ✅ Scroll interno (no se corta)
// ✅ Lista de items con miniaturas + subtotal
//
// ✅ PEDIDO (LO QUE PEDISTE):
// - Ubicación: muestra DIRECCIÓN (no lat/lng)
// - Cliente: muestra NOMBRE (no uid) -> se trae de /usuarios/{uid}
// - “Pedido ID” ahora muestra el CÓDIGO del pedido
// - Estado: si está en "pendiente" permite cambiar a "Aceptado"
// - Permite editar "fecha_envio" (DateTime picker)
// - Permite editar "costo_envio"
// - Permite asignar repartidor del MISMO DEPARTAMENTO del pedido
//   -> repartidores filtrados por almacenId (del pedido o por almacenes del depto)
// - En dropdown de repartidor: SOLO NOMBRE (sin correo)
//
// Uso:
// showPedidoDetalleDialog(context, pedidoData, pedidoId: doc.id);

// lib/features/pedidos/views/detalle_pedido.dart
// UI-only dialog for pedido detalle. All data/logic is in controller/data.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quimisol_web/core/theme/palette.dart';

import '../controllers/detalle_controller.dart';
import '../data/detalle_data.dart';
import '../data/repartidor_option.dart';

import 'widgets/detalle_widgets/empty_box.dart';
import 'widgets/detalle_widgets/entrega_info.dart';
import 'widgets/detalle_widgets/estado_editor.dart';
import 'widgets/detalle_widgets/estado_pill.dart';
import 'widgets/detalle_widgets/section_card.dart';
import 'widgets/detalle_widgets/warn_box.dart';

// Exclusivamente con pedidoId.
Future<void> showPedidoDetalleDialog(
  BuildContext context,
  String pedidoId, {
  PedidoDetalleController? controller,
}) {
  final ctrl = controller ?? PedidoDetalleController();
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _PedidoDetalleDialog(pedidoId: pedidoId, controller: ctrl),
  );
}

class _PedidoDetalleDialog extends StatelessWidget {
  const _PedidoDetalleDialog({
    required this.pedidoId,
    required this.controller,
  });

  final String pedidoId;
  final PedidoDetalleController controller;

  @override
  Widget build(BuildContext context) {
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
              child: FutureBuilder<PedidoDetalleData>(
                future: controller.fetchPedido(pedidoId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return SizedBox(
                      height: 240,
                      child: Center(
                        child: Text('Error cargando pedido: \\${snap.error}'),
                      ),
                    );
                  }
                  final data = snap.data!;
                  return _PedidoDetalleForm(
                    pedido: data,
                    controller: controller,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PedidoDetalleForm extends StatefulWidget {
  const _PedidoDetalleForm({required this.pedido, required this.controller});

  final PedidoDetalleData pedido;
  final PedidoDetalleController controller;

  @override
  State<_PedidoDetalleForm> createState() => _PedidoDetalleFormState();
}

class _PedidoDetalleFormState extends State<_PedidoDetalleForm> {
  bool _saving = false;

  // editable local state
  late String _estadoEdit;
  DateTime? _fechaEnvioEdit;
  double? _costoEnvioEdit;
  String? _repartidorUidEdit;
  late TextEditingController _costoCtrl;

  @override
  void initState() {
    super.initState();

    _estadoEdit = widget.pedido.estado;
    _fechaEnvioEdit = widget.pedido.fechaEnvio;
    _costoEnvioEdit = widget.pedido.costoEnvio;
    _repartidorUidEdit = widget.pedido.repartidorUid;
    _costoCtrl = TextEditingController(
      text: _moneyNoSuffix(_costoEnvioEdit ?? 0),
    );
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Palette.primary,
            primary: Palette.primary,
            secondary: Palette.button,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Palette.primary,
            primary: Palette.primary,
            secondary: Palette.button,
          ),
        ),
        child: child!,
      ),
    );

    setState(() {
      _fechaEnvioEdit = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? initial.hour,
        time?.minute ?? initial.minute,
      );
    });
  }

  void _applyCostoFromText() {
    final raw = _costoCtrl.text.trim();
    final v = _parseMoney(raw);
    setState(() => _costoEnvioEdit = v < 0 ? 0 : v);
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    _applyCostoFromText();

    try {
      await widget.controller.guardarCambios(
        data: widget.pedido,
        nuevoEstado: _estadoEdit,
        fechaEnvio: _fechaEnvioEdit,
        costoEnvio: _costoEnvioEdit ?? 0,
        repartidorUid: _repartidorUidEdit,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pedido actualizado ✅')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: \\$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final totalProductos = pedido.totalProductos;
    final costoEnvio = _costoEnvioEdit ?? pedido.costoEnvio;
    final totalFinal = totalProductos + costoEnvio;

    final createdText = _formatTs(pedido.createdAt);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // HEADER
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
                      'Pedido #${pedido.codigo}',
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

              EstadoPill(estado: pedido.estado),
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

        // BODY
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, c) {
                    final isWide = c.maxWidth >= 780;

                    final left = SectionCard(
                      title: 'Entrega',
                      icon: Icons.location_on_rounded,
                      child: EntregaInfo(
                        ubNombre: '',
                        /* opcional */ 
                        direccion: pedido.direccion,
                        departamento: pedido.departamento,
                      ),
                    );

                    final right = SectionCard(
                      title: 'Cliente',
                      icon: Icons.person_rounded,
                      child: _ClienteInfo(
                        nombre: pedido.clienteNombre,
                        email: pedido.clienteEmail,
                        codigoPedido: pedido.codigo,
                        conteo: pedido.items.length.toString(),
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
                      children: [left, const SizedBox(height: 14), right],
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Gestión
                SectionCard(
                  title: 'Gestión',
                  icon: Icons.tune_rounded,
                  child: Column(
                    children: [
                      _EditRow(
                        label: 'Estado',
                        child: EstadoEditor(
                          estadoActual: pedido.estado,
                          value: _estadoEdit,
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
                                      : DateFormat(
                                          'dd/MM/yyyy HH:mm',
                                          'es_BO',
                                        ).format(_fechaEnvioEdit!),
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
                                  color: Palette.primary.withValues(
                                    alpha: 0.30,
                                  ),
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
                                      color: Palette.ink.withValues(
                                        alpha: 0.45,
                                      ),
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
                                    color: Palette.primary.withValues(
                                      alpha: 0.10,
                                    ),
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
                          departamentoPedido: pedido.departamento,
                          pedidoAlmacenId: pedido.almacenId,
                          valueUid: _repartidorUidEdit,
                          onChanged: (uid) =>
                              setState(() => _repartidorUidEdit = uid),
                          controller: widget.controller,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Items
                SectionCard(
                  title: 'Productos',
                  icon: Icons.shopping_bag_rounded,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Palette.button.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Palette.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      '${pedido.items.length}',
                      style: TextStyle(
                        color: Palette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  child: pedido.items.isEmpty
                      ? const EmptyBox(text: 'No hay items en este pedido.')
                      : Column(
                          children: [
                            for (int i = 0; i < pedido.items.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: i == pedido.items.length - 1 ? 0 : 10,
                                ),
                                child: _ItemTileTyped(item: pedido.items[i]),
                              ),
                          ],
                        ),
                ),

                const SizedBox(height: 14),

                // Totals
                SectionCard(
                  title: 'Totales',
                  icon: Icons.calculate_rounded,
                  child: _KeyValueList(
                    rows: [
                      _KV('Total productos', _money(totalProductos)),
                      _KV('Costo envío', _money(costoEnvio)),
                      _KV('Total final', _money(totalFinal), isStrong: true),
                    ],
                  ),
                ),

                // FOOTER
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: BoxDecoration(
                    color: Palette.fieldBg,
                    border: Border(
                      top: BorderSide(
                        color: Palette.ink.withValues(alpha: 0.06),
                      ),
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
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Palette.primary,
                          side: BorderSide(
                            color: Palette.primary.withValues(alpha: 0.25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClienteInfo extends StatelessWidget {
  const _ClienteInfo({
    required this.nombre,
    required this.email,
    required this.codigoPedido,
    required this.conteo,
  });

  final String nombre;
  final String email;
  final String codigoPedido;
  final String conteo;

  @override
  Widget build(BuildContext context) {
    return _KeyValueList(
      rows: [
        _KV('Nombre', nombre.isEmpty ? '—' : nombre),
        _KV('Email', email.isEmpty ? '—' : email),
        _KV(
          'Pedido',
          codigoPedido.isEmpty ? '—' : '#$codigoPedido',
          isStrong: true,
        ),
        _KV('Conteo Productos', conteo),
      ],
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

class _RepartidorPicker extends StatelessWidget {
  const _RepartidorPicker({
    required this.enabled,
    required this.departamentoPedido,
    required this.pedidoAlmacenId,
    required this.valueUid,
    required this.onChanged,
    required this.controller,
  });

  final bool enabled;
  final String departamentoPedido;
  final String pedidoAlmacenId; // puede venir vacío
  final String? valueUid;
  final ValueChanged<String?> onChanged;
  final PedidoDetalleController controller;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    if (departamentoPedido.trim().isEmpty && pedidoAlmacenId.trim().isEmpty) {
      return const WarnBox(
        text:
            'Este pedido no tiene "departamento" ni "almacenId". No se puede filtrar repartidores.',
      );
    }

    return FutureBuilder<List<RepartidorOption>>(
      future: controller
          .fetchRepartidores(
            departamento: departamentoPedido,
            almacenId: pedidoAlmacenId,
          )
          .then(
            (docs) => docs
                .map((d) => RepartidorOption.fromFirestore(d))
                .toList(growable: false),
          ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _ghostField('Cargando repartidores…', ink);
        }
        if (snap.hasError) {
          return WarnBox(text: 'Error obteniendo repartidores: ${snap.error}');
        }

        final options = snap.data ?? [];
        if (options.isEmpty) {
          final extra = pedidoAlmacenId.trim().isNotEmpty
              ? 'del almacén del pedido'
              : 'de almacenes en "$departamentoPedido"';
          return WarnBox(text: 'No hay repartidores $extra.');
        }

        final exists =
            valueUid != null && options.any((o) => o.uid == valueUid);
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
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ink.withValues(alpha: 0.55),
              ),
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w900,
                fontSize: 12.8,
              ),
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
                ...options.map(
                  (o) => DropdownMenuItem<String?>(
                    value: o.uid,
                    child: Text(
                      o.nombre, // ✅ SOLO NOMBRE
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

/* ===================== ITEMS ===================== */

// legacy untyped item tile is removed - use _ItemTileTyped which consumes `PedidoItemData`.

class _ItemTileTyped extends StatelessWidget {
  const _ItemTileTyped({required this.item});
  final PedidoItemData item;

  @override
  Widget build(BuildContext context) {
    final ink = Palette.ink;

    final name = item.nombre;
    final imageUrl = item.imageUrl;
    final qty = item.cantidad;
    final price = item.precio;
    final subtotal = item.subtotal;

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
              border: Border.all(
                color: Palette.primary.withValues(alpha: 0.10),
              ),
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
            ? Icon(
                Icons.image_not_supported_rounded,
                color: Palette.primary.withValues(alpha: 0.6),
              )
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

/* ===================== LISTS / BOXES ===================== */

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
                      fontWeight: rows[i].isStrong
                          ? FontWeight.w900
                          : FontWeight.w800,
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

/* ===================== HELPERS ===================== */

String _money(double v) {
  final f = NumberFormat('#,##0.00', 'es_BO');
  return '${f.format(v)} Bs';
}

String _moneyNoSuffix(double v) {
  final f = NumberFormat('#,##0.00', 'es_BO');
  return f.format(v);
}

double _parseMoney(String raw) {
  // admite "1.234,50" o "1234.50"
  final s = raw
      .replaceAll('Bs', '')
      .replaceAll('bs', '')
      .replaceAll(' ', '')
      .trim();
  if (s.isEmpty) return 0;
  // si tiene coma y punto, asumimos formato es: "." miles, "," decimal
  if (s.contains(',') && s.contains('.')) {
    final normalized = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }
  // si solo tiene coma, la tratamos como decimal
  if (s.contains(',') && !s.contains('.')) {
    return double.tryParse(s.replaceAll(',', '.')) ?? 0;
  }
  return double.tryParse(s) ?? 0;
}

String _formatTs(DateTime? dt) {
  if (dt == null) return '';
  return DateFormat('dd/MM/yyyy HH:mm', 'es_BO').format(dt);
}

class _KV {
  final String k;
  final String v;
  final bool isStrong;
  const _KV(this.k, this.v, {this.isStrong = false});
}