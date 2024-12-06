import 'package:fit_app/login_screen.dart';
import 'package:fit_app/splash_screen.dart';
import 'package:flutter/material.dart';
import 'macro_tracking_page.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fit App',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.green,
          surface: Colors.white,
          background: Colors.white,
          inversePrimary: Colors.black.withOpacity(0.9),
        ),
        useMaterial3: true,
        primaryColor: Colors.black,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/macroTracking': (context) => const MacroTrackingPage(),
      },
    );
  }
}