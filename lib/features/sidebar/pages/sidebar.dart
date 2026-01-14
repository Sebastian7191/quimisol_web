// lib/features/shell/sidebar_shell_page.dart
//
// ✅ Agregado "Pedidos" al sidebar + pages
// ✅ IndexFromPath actualizado para /pedidos
// ✅ Import de la nueva page PedidosPage (la que te pasé)
//
// OJO: ajusta el import de PedidosPage según dónde lo guardaste.
// En mi ejemplo anterior: lib/features/admin/pedidos/pedidos_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:quimisol_web/core/theme/palette.dart';

import 'package:quimisol_web/features/almacenes/views/almacenes.dart';
import 'package:quimisol_web/features/home/pages/views/dashboard_page.dart';

import 'package:quimisol_web/features/pedidos/views/pedidos.dart';
import 'package:quimisol_web/features/productos/views/productos.dart';
import 'package:quimisol_web/features/unidades/views/unidades.dart';
import 'package:quimisol_web/features/usuarios/views/usuarios.dart';


class SidebarShellPage extends StatefulWidget {
  const SidebarShellPage({super.key});

  @override
  State<SidebarShellPage> createState() => _SidebarShellPageState();
}

class _SidebarShellPageState extends State<SidebarShellPage> {
  int _currentIndex = 0;

  bool _sidebarOpen = false;
  bool _hoveringSidebar = false;
  bool _hoveringTrigger = false;

  Timer? _closeTimer;

  // 🎨 Colores
  Color get _main => Palette.button; // rosa
  Color get _accent => Palette.primary; // morado

  final List<_SideItem> _items = const [
    _SideItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    _SideItem(
      icon: Icons.people_alt_rounded,
      label: 'Usuarios',
      route: '/usuarios',
    ),
    _SideItem(
      icon: Icons.warehouse_rounded,
      label: 'Almacenes',
      route: '/almacenes',
    ),
    _SideItem(
      icon: Icons.inventory_2_rounded,
      label: 'Productos',
      route: '/productos',
    ),
    _SideItem(
      icon: Icons.straighten_rounded,
      label: 'Unidades',
      route: '/unidades',
    ),

    // ✅ NUEVO: PEDIDOS
    _SideItem(
      icon: Icons.receipt_long_rounded,
      label: 'Pedidos',
      route: '/pedidos',
    ),
  ];

  void _cancelCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  void _openSidebar() {
    _cancelCloseTimer();
    if (!_sidebarOpen) setState(() => _sidebarOpen = true);
  }

  void _scheduleClose() {
    _cancelCloseTimer();
    _closeTimer = Timer(const Duration(milliseconds: 160), () {
      final keepOpen = _hoveringSidebar || _hoveringTrigger;
      if (!keepOpen && mounted) setState(() => _sidebarOpen = false);
    });
  }

  /// ✅ Mapea URL -> índice del sidebar
  int _indexFromPath(String path) {
    if (path.startsWith('/usuarios')) return 1;
    if (path.startsWith('/almacenes')) return 2; // incluye /almacenes/:id
    if (path.startsWith('/productos')) return 3;
    if (path.startsWith('/unidades')) return 4;

    // ✅ NUEVO
    if (path.startsWith('/pedidos')) return 5;

    return 0; // dashboard por defecto
  }

  void _syncIndexWithPath(String path) {
    final idx = _indexFromPath(path);
    if (idx != _currentIndex && mounted) {
      setState(() => _currentIndex = idx);
    }
  }

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    // ❌ NO navegar aquí para evitar remount / sensación de otra página
  }

  @override
  void initState() {
    super.initState();

    // ✅ primera sincronización post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Modular.to.path;

      // Si entras a "/" -> mandamos a dashboard
      if (p == '/' || p.isEmpty) {
        Modular.to.navigate('/dashboard');
        _syncIndexWithPath('/dashboard');
      } else {
        _syncIndexWithPath(p);
      }
    });

    // ✅ si cambias URL manualmente o recargas
    Modular.to.addListener(() {
      if (!mounted) return;
      _syncIndexWithPath(Modular.to.path);
    });
  }

  @override
  void dispose() {
    _cancelCloseTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardPage(),
      const UsuariosPage(),
      const AlmacenesPage(),
      const ProductosPage(),
      const UnidadesPage(),

      // ✅ NUEVO
      const PedidosPage(),
    ];

    return Scaffold(
      backgroundColor: Palette.fieldBg,
      body: Row(
        children: [
          /// 🔹 TRIGGER (borde izquierdo)
          MouseRegion(
            onEnter: (_) {
              _hoveringTrigger = true;
              _openSidebar();
            },
            onExit: (_) {
              _hoveringTrigger = false;
              _scheduleClose();
            },
            child: const SizedBox(width: 6, height: double.infinity),
          ),

          /// 🔹 SIDEBAR (pegado a la izquierda)
          MouseRegion(
            onEnter: (_) {
              _hoveringSidebar = true;
              _openSidebar();
            },
            onExit: (_) {
              _hoveringSidebar = false;
              _scheduleClose();
            },
            child: _Sidebar(
              isOpen: _sidebarOpen,
              currentIndex: _currentIndex,
              items: _items,
              mainColor: _main,
              accentColor: _accent,
              onChanged: _goTo,
            ),
          ),

          /// 🔹 BODY (siempre visible)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: Palette.white,
                  child: pages[_currentIndex],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideItem {
  final IconData icon;
  final String label;
  final String route;

  const _SideItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _Sidebar extends StatelessWidget {
  final bool isOpen;
  final int currentIndex;
  final List<_SideItem> items;
  final Color mainColor;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const _Sidebar({
    required this.isOpen,
    required this.currentIndex,
    required this.items,
    required this.mainColor,
    required this.accentColor,
    required this.onChanged,
  });

  static const double _openWidth = 288;
  static const double _closedWidth = 86;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isOpen ? _openWidth : _closedWidth,
      decoration: BoxDecoration(
        color: Palette.white,
        border: Border(right: BorderSide(color: mainColor.withValues(alpha: 0.55))),
      ),
      child: Column(
        children: [
          _SidebarHeader(
            open: isOpen,
            mainColor: mainColor,
            accentColor: accentColor,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final selected = i == currentIndex;
                return _SidebarItemTile(
                  open: isOpen,
                  selected: selected,
                  icon: items[i].icon,
                  label: items[i].label,
                  mainColor: mainColor,
                  onTap: () => onChanged(i),
                );
              },
            ),
          ),
          _SidebarFooter(open: isOpen),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool open;
  final Color mainColor;
  final Color accentColor;

  const _SidebarHeader({
    required this.open,
    required this.mainColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            mainColor.withValues(alpha: 0.95),
            Palette.secondary.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Palette.white,
            child: Icon(Icons.business_rounded, color: accentColor),
          ),
          if (open) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quimisol Admin',
                    style: TextStyle(
                      color: Palette.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Panel de control',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Icon(
            open ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            color: Palette.white.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemTile extends StatelessWidget {
  final bool open;
  final bool selected;
  final IconData icon;
  final String label;
  final Color mainColor;
  final VoidCallback onTap;

  const _SidebarItemTile({
    required this.open,
    required this.selected,
    required this.icon,
    required this.label,
    required this.mainColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? mainColor.withValues(alpha: 0.22) : Colors.transparent;
    final iconColor = selected ? Palette.primary : Palette.ink;
    final textColor = selected ? Palette.primary : Palette.ink;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? mainColor.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: open ? 14 : 10,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              if (open) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final bool open;
  const _SidebarFooter({required this.open});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Palette.ink.withValues(alpha: 0.8),
          ),
          if (open) ...[
            const SizedBox(width: 8),
            Text(
              'Admin • Web',
              style: TextStyle(
                fontSize: 12,
                color: Palette.ink.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
