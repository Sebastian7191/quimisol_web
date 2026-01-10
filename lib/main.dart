import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:firebase_core/firebase_core.dart';

// ✅ Locales (para DateFormat con 'es_BO' y DatePicker/TimePicker en español)
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app_module.dart';
import 'app_widget.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Inicializa datos de locale para Intl (evita LocaleDataException)
  await initializeDateFormatting('es_BO', null);
  Intl.defaultLocale = 'es_BO';

  runApp(
    ModularApp(
      module: AppModule(),
      child: const AppWidget(),
    ),
  );
}
