import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/food_log_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isOnboardingComplete = prefs.getBool('is_onboarding_complete') ?? false;
  runApp(FitMacroApp(isOnboardingComplete: isOnboardingComplete));
}

class FitMacroApp extends StatelessWidget {
  final bool isOnboardingComplete;
  const FitMacroApp({super.key, required this.isOnboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitMacro AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1a7a3c)),
        useMaterial3: true,
      ),
      home: isOnboardingComplete ? const FoodLogScreen() : const SplashScreen(),
    );
  }
}