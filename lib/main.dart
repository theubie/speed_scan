import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speed_scan/models/equipment_model.dart';
import 'package:speed_scan/screens/main_screen.dart';

void main() async {
  // Initialize Hive and register the adapter
  await Hive.initFlutter();
  Hive.registerAdapter(EquipmentAdapter());

  // Open the box for storing equipment entries
  await Hive.openBox<Equipment>('equipmentBox');

  runApp(const SpeedScanApp());
}

class SpeedScanApp extends StatelessWidget {
  const SpeedScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speed Scan',
      theme: _buildDarkTheme(),
      home: const MainScreen(),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.teal,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      colorScheme: const ColorScheme.dark(
        primary: Colors.teal,
        secondary: Colors.tealAccent,
        surface: Color(0xFF1E1E1E),
        error: Color.fromARGB(255, 100, 18, 12),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        color: Color(0xFF1F1F1F),
        elevation: 4.0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.tealAccent,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 18.0, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 16.0, color: Colors.white70),
        bodySmall: TextStyle(fontSize: 14.0, color: Colors.white60),
        labelLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.tealAccent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
    );
  }
}
