import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize Firebase. If config is not provisioned yet, the app falls back to Mock repositories.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed or was skipped. Using simulated offline mode: $e');
  }

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

    return MaterialApp.router(
      title: 'MAARG Emergency Assistant',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
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
      ),
    );
  }
}
