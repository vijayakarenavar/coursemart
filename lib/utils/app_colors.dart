/// App Colors
///
/// Centralized color constants for the CourseMart app.
/// Import this file wherever colors are needed:
///   import '../../utils/app_colors.dart';
library;

import 'package:flutter/material.dart';

class AppColors {
  // Private constructor — prevent instantiation
  AppColors._();

  // ── Primary ──────────────────────────────
  static const primary      = Color(0xFF0D2137);
  static const primaryLight = Color(0xFF1a3a5c);

  // ── Accent ───────────────────────────────
  static const cyan         = Color(0xFF29D9D5);
  static const cyanDark     = Color(0xFF1fb8b4);
  static const cyanLight    = Color(0xFFE0FAFA);

  // ── Background & Surface ─────────────────
  static const bg           = Color(0xFFF0F4F8);
  static const card         = Colors.white;
  static const progressBarBg = Color(0xFFE8F0F8);

  // ── Text ─────────────────────────────────
  static const text         = Color(0xFF0D2137);
  static const text2        = Color(0xFF6B7A99);

  // ── Status ───────────────────────────────
  static const green        = Color(0xFF4CAF81);
  static const pink         = Color(0xFFFF6B9D);
  static const red          = Color(0xFFE53935);
}