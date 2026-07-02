import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../services/notification_router.dart';
import 'app_routes.dart';

class MerkDirApp extends StatefulWidget {
  const MerkDirApp({super.key});

  @override
  State<MerkDirApp> createState() => _MerkDirAppState();
}

class _MerkDirAppState extends State<MerkDirApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      openPendingNotificationIfAny();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      locale: currentLocale,

      localizationsDelegates:
        AppLocalizations.localizationsDelegates,

      supportedLocales:
        AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: Text(
                details.exceptionAsString(),
              ),
            ),
          );
        };
        return child!;
      },
      title: 'MerkDir',

      theme: ThemeData(
        brightness: Brightness.dark,

        scaffoldBackgroundColor: const Color(0xFF1E1E1E),

        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFF8C00),
          secondary: const Color(0xFFFF8C00),
          surface: const Color(0xFF2A2A2A),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A2A2A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        cardColor: const Color(0xFF2A2A2A),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFFF8C00),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
