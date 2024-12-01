import 'package:flutter/material.dart';
import 'colo_extension.dart'; // Assuming TColor is defined here

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default theme mode

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notify listeners to update UI
  }

  // Define light theme
  ThemeData get lightTheme => ThemeData(
        primaryColor: TColor.primaryColor1,
        fontFamily: "Poppins",
        scaffoldBackgroundColor: TColor.lightGray,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.grey),
        ),
      );

  // Define dark theme
  ThemeData get darkTheme => ThemeData(
        primaryColor: TColor.nightPrimaryColor1,
        fontFamily: "Poppins",
        scaffoldBackgroundColor: TColor.nightBlack,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.grey),
        ),
      );
}
