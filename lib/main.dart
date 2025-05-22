import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart' as app_models;
import 'package:finanz_app/core/presentation/screens/home_screen.dart';
import 'package:finanz_app/core/presentation/screens/splash_screen.dart';
import 'package:finanz_app/core/data/database/database_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar AdMob
  await MobileAds.instance.initialize();

  // Inicializar la base de datos
  final dbService = DatabaseService();
  await dbService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => app_models.AppState(),
      child: const FinanzApp(),
    ),
  );
}

class FinanzApp extends StatelessWidget {
  const FinanzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanz App',
      theme: Provider.of<app_models.AppState>(context).currentTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
