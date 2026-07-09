import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4FACFE);
  static const Color secondary = Color(0xFF00F2FE);

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      primary,
      secondary,
    ],
  );

  static const Color cardColor = Colors.white24;
  static const Color textColor = Colors.white;
}