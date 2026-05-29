import 'package:flutter/material.dart';

// ── Colour palette (matches Android Compose theme) ──────────────────────────
const Color kPrimary         = Color(0xFF1565C0);
const Color kAppBackground   = Color(0xFFF0F4FF);
const Color kCardBackground  = Color(0xFFFFFFFF);
const Color kButtonSecondary = Color(0xFFE8EEF9);
const Color kTextPrimary     = Color(0xFF1A1A2E);
const Color kTextSecondary   = Color(0xFF6B7280);
const Color kDividerColor    = Color(0xFFE0E7FF);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimary,
    primary: kPrimary,
    surface: kAppBackground,
  ),
  scaffoldBackgroundColor: kAppBackground,
);
