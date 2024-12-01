import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this import
import 'package:fitness/view/main_tab/main_tab_view.dart';
import 'package:fitness/common/theme_provider.dart'; // Import ThemeProvider
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:fitness/view/on_boarding/on_boarding_view.dart';
import 'package:fitness/view/on_boarding/started_view.dart'; // Import Starter View

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  // If it is the first time, set 'isFirstTime' to false
  if (isFirstTime) {
    await prefs.setBool('isFirstTime', false);
  }

  runApp(MyApp(isFirstTime: isFirstTime));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Fitness App',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme, // Apply light theme
            darkTheme: themeProvider.darkTheme, // Apply dark theme
            themeMode: themeProvider.themeMode, // Control theme mode
            home: isFirstTime
                ? StartedView()
                : MainTabView(
                    onThemeToggle: () {
                      themeProvider.toggleTheme(); // Toggle theme when button is pressed
                    },
                  ),
          );
        },
      ),
    );
  }
}
