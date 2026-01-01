import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol_web/features/sidebar/pages/sidebar.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {}

  @override
  void routes(RouteManager r) {
    // ✅ Todas estas rutas cargan el MISMO Shell (sidebar)
    r.child('/', child: (_) => const SidebarShellPage());
    r.child('/dashboard', child: (_) => const SidebarShellPage());
    r.child('/usuarios', child: (_) => const SidebarShellPage());
    r.child('/almacenes', child: (_) => const SidebarShellPage());
    r.child('/productos', child: (_) => const SidebarShellPage());
    r.child('/unidades', child: (_) => const SidebarShellPage());

    // ✅ futuras rutas hijas (también deben ir al shell)
    r.child('/almacenes/:id', child: (_) => const SidebarShellPage());
  }
}
