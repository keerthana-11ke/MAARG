import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'widgets/shake_sos_wrapper.dart';

import 'screens/sos_countdown_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Set up SOS channel globally
  const channel = MethodChannel('maarg/sos');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'sos_triggered') {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const SOSCountdownScreen(),
        ),
      );
    }
    return null;
  });
  
  runApp(
    const ProviderScope(
      child: MaargApp(),
    ),
  );
}

class MaargApp extends StatelessWidget {
  const MaargApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFFE53935);
    final Color darkBg = const Color(0xFF121212);
    final Color darkSurface = const Color(0xFF1E1E1E);

    final elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 56),
      ),
    );
    final outlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 56),
      ),
    );
    final textButtonTheme = TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 56),
      ),
    );

    return MaterialApp.router(
      title: 'MAARG Emergency Assistant',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      builder: (context, child) => ShakeSosWrapper(child: child!),
      themeMode: ThemeMode.dark, // Defaulting to Dark Mode for high visibility in stress situations
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: primaryRed,
          onPrimary: Colors.white,
          secondary: Colors.amber,
          surface: Colors.white,
          error: primaryRed,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: elevatedButtonTheme,
        outlinedButtonTheme: outlinedButtonTheme,
        textButtonTheme: textButtonTheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primaryRed,
          onPrimary: Colors.white,
          secondary: Colors.amber,
          surface: darkSurface,
          error: primaryRed,
        ),
        scaffoldBackgroundColor: darkBg,
        cardTheme: CardThemeData(
          color: darkSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkBg,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: elevatedButtonTheme,
        outlinedButtonTheme: outlinedButtonTheme,
        textButtonTheme: textButtonTheme,
      ),
    );
  }
}
