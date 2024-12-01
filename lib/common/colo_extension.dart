import 'package:flutter/material.dart';

class TColor {
  // Light mode colors
  static Color get primaryColor1 => const Color(0xff92A3FD);
  static Color get primaryColor2 => const Color(0xff9DCEFF);
  static Color get secondaryColor1 => const Color(0xffC58BF2);
  static Color get secondaryColor2 => const Color(0xffEEA4CE);

  static List<Color> get primaryG => [primaryColor2, primaryColor1];
  static List<Color> get secondaryG => [secondaryColor2, secondaryColor1];

  static Color get black => const Color(0xff1D1617);
  static Color get gray => const Color(0xff786F72);
  static Color get white => Colors.white;
  static Color get lightGray => const Color(0xffF7F8F8);

  // Night mode colors
  static Color get nightPrimaryColor1 => const Color(0xff0D47A1);
  static Color get nightPrimaryColor2 => const Color(0xff1E88E5);
  static Color get nightSecondaryColor1 => const Color(0xff6A1B9A);
  static Color get nightSecondaryColor2 => const Color(0xff8E24AA);

  static List<Color> get nightPrimaryG => [nightPrimaryColor2, nightPrimaryColor1];
  static List<Color> get nightSecondaryG => [nightSecondaryColor2, nightSecondaryColor1];

  static Color get nightBlack => const Color(0xff121212);
  static Color get nightGray => const Color(0xff424242);
  static Color get nightWhite => const Color(0xffE0E0E0);
  static Color get nightLightGray => const Color(0xff303030);
}
