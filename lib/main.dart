import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'data/db_factory.dart';
import 'screens/calculator_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    setupDatabaseFactory();
  } catch (e) {
    debugPrint('Database initialization notice: $e');
  }

  // Prevent any white or unstyled error screens across all platforms
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: kBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: kOrange, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBg,
        canvasColor: kBg,
        dialogTheme: const DialogThemeData(backgroundColor: kBtnBase),
        colorScheme: const ColorScheme.dark(
          primary: kOrange,
          surface: kBtnBase,
        ),
      ),
      home: const CalculatorScreen(),
    );
  }
}
