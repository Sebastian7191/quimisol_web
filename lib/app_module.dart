import 'package:flutter_modular/flutter_modular.dart';
import 'package:quimisol_web/features/sidebar/pages/sidebar.dart';

import 'app_widget.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    // Aquí luego vas agregando tus services, repositories, stores, controllers, etc.
    // Ej:
    // i.addSingleton<AuthService>(AuthServiceImpl.new);
  }

  @override
  void routes(RouteManager r) {
    // Ruta raíz: normalmente muestra AppWidget (que a su vez contiene el router)
    r.child('/', child: (_) => const SidebarShellPage());

    // Ejemplo opcional (por si quieres tener una pantalla “home” separada luego)
    // r.child(
    //   '/home',
    //   child: (_) => const HomePage(),
    // );
  }
}
