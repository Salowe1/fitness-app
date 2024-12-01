import 'package:fitness/common/colo_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:fitness/common/theme_provider.dart'; // Import ThemeProvider

class BlankView extends StatefulWidget {
  const BlankView({super.key});

  @override
  State<BlankView> createState() => _BlankViewState();
}

class _BlankViewState extends State<BlankView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.themeMode == ThemeMode.light
              ? TColor.white
              : TColor.nightBlack, // Switch background based on theme
          body: Center(
            child: Text(
              'Blank View',
              style: TextStyle(
                color: themeProvider.themeMode == ThemeMode.light
                    ? Colors.black
                    : Colors.white, // Text color changes based on theme
              ),
            ),
          ),
        );
      },
    );
  }
}
