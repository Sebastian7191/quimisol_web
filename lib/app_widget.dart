// lib/app_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quimisol Web',
      debugShowCheckedModeBanner: false,
      routerConfig: Modular.routerConfig,

      // ✅ Calendario / TimePicker en Español
      locale: const Locale('es', 'BO'),
      supportedLocales: const [
        Locale('es', 'BO'),
        Locale('es', 'ES'),
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}
