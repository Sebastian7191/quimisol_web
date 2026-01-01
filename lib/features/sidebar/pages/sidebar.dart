import 'dart:async';
import 'package:flutter/material.dart';

import 'package:quimisol_web/core/theme/palette.dart';

import 'package:quimisol_web/features/almacenes/pages/almacenes.dart';
import 'package:quimisol_web/features/home/pages/dashboard.dart';
import 'package:quimisol_web/features/productos/pages/productos.dart';
import 'package:quimisol_web/features/unidades/pages/unidades.dart';
import 'package:quimisol_web/features/usuarios/pages/usuarios.dart';

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
  Color get _main => Palette.button;   // rosa
  Color get _accent => Palette.primary; // morado

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
      if (!keepOpen && mounted) {
        setState(() => _sidebarOpen = false);
      }
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
    ];

    final items = const <_SideItem>[
      _SideItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
      _SideItem(icon: Icons.people_alt_rounded, label: 'Usuarios'),
      _SideItem(icon: Icons.warehouse_rounded, label: 'Almacenes'),
      _SideItem(icon: Icons.inventory_2_rounded, label: 'Productos'),
      _SideItem(icon: Icons.straighten_rounded, label: 'Unidades'),
    ];

    return Scaffold(
      backgroundColor: Palette.fieldBg,
      body: Row(
        children: [
          /// 🔹 ZONA TRIGGER (borde izquierdo)
          MouseRegion(
            onEnter: (_) {
              _hoveringTrigger = true;
              _openSidebar();
            },
            onExit: (_) {
              _hoveringTrigger = false;
              _scheduleClose();
            },
            child: const SizedBox(width: 6),
          ),

          /// 🔹 SIDEBAR PEGADO
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
              items: items,
              mainColor: _main,
              accentColor: _accent,
              onChanged: (i) => setState(() => _currentIndex = i),
            ),
          ),

          /// 🔹 BODY
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
  const _SideItem({required this.icon, required this.label});
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
        border: Border(
          right: BorderSide(color: mainColor.withOpacity(0.55)),
        ),
      ),
      child: Column(
        children: [
          _SidebarHeader(open: isOpen, mainColor: mainColor, accentColor: accentColor),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final selected = i == currentIndex;
                return _SidebarItem(
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
            mainColor.withOpacity(0.95),
            Palette.secondary.withOpacity(0.9),
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
                  Text('Quimisol Admin',
                      style: TextStyle(color: Palette.white, fontWeight: FontWeight.w800)),
                  Text('Panel de control',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final bool open;
  final bool selected;
  final IconData icon;
  final String label;
  final Color mainColor;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.open,
    required this.selected,
    required this.icon,
    required this.label,
    required this.mainColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? mainColor.withOpacity(0.22) : Colors.transparent;
    final iconColor = selected ? Palette.primary : Palette.ink;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: bg),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: open ? 14 : 10, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              if (open) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
          Icon(Icons.info_outline_rounded, size: 18, color: Palette.ink),
          if (open) ...[
            const SizedBox(width: 8),
            const Text('Admin • Web', style: TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
