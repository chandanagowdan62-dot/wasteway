import 'package:flutter/material.dart';

/// Centralized color palette for WasteWay following Material 3 guidelines.
class AppColors {
  AppColors._();

  // Primary brand colors (Eco-Emerald / Forest Green)
  static const Color primaryGreen = Color(0xFF1E7E34);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF0F4D19);

  // Secondary accents (Earth / Amber / Clean Teal)
  static const Color secondaryTeal = Color(0xFF00796B);
  static const Color accentAmber = Color(0xFFF57F17);
  static const Color alertRed = Color(0xFFD32F2F);

  // Background and surface colors
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121413);
  static const Color cardDark = Color(0xFF1E2220);

  // Recyclability Grade Colors (A to E)
  static const Color gradeA = Color(0xFF2E7D32); // High recyclability (Green)
  static const Color gradeB = Color(0xFF558B2F); // Good (Light Green)
  static const Color gradeC = Color(0xFFF9A825); // Moderate (Amber)
  static const Color gradeD = Color(0xFFE65100); // Low (Orange)
  static const Color gradeE = Color(0xFFC62828); // Not Recyclable / Hazardous (Red)

  // Status colors for Civic Reports (Module 8)
  static const Color statusSubmitted = Color(0xFF1976D2);
  static const Color statusUnderReview = Color(0xFFF57C00);
  static const Color statusEscalated = Color(0xFF7B1FA2);
  static const Color statusResolved = Color(0xFF388E3C);
}
