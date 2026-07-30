import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const BalloonCampApp(),
    ),
  );
}

class BalloonCampApp extends StatelessWidget {
  const BalloonCampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balloon Camp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE94560),
          surface: const Color(0xFF16213E),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginScreen(),
        '/main': (_) => const MainScreen(),
      },
    );
  }
}
