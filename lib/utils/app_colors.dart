/// App Colors
///
/// Centralized color constants for the CourseMart app.
/// Dark Mode + Light Mode दोन्ही support करतो.
/// Import this file wherever colors are needed:
///   import '../../utils/app_colors.dart';
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary ──────────────────────────────
  static const primary      = Color(0xFF0D2137);
  static const primaryLight = Color(0xFF1a3a5c);

  // ── Accent ───────────────────────────────
  static const cyan         = Color(0xFF29D9D5);
  static const cyanDark     = Color(0xFF1fb8b4);
  static const cyanLight    = Color(0xFFE0FAFA);

  // ── Light Mode Background & Surface ──────
  static const bg           = Color(0xFFF0F4F8);
  static const card         = Colors.white;
  static const progressBarBg = Color(0xFFE8F0F8);

  // ── Dark Mode Background & Surface ───────
  static const bgDark           = Color(0xFF0A0F1A);
  static const cardDark         = Color(0xFF111827);
  static const progressBarBgDark = Color(0xFF1E293B);
  static const surfaceDark      = Color(0xFF1E293B);

  // ── Light Mode Text ───────────────────────
  static const text         = Color(0xFF0D2137);
  static const text2        = Color(0xFF6B7A99);

  // ── Dark Mode Text ────────────────────────
  static const textDark     = Color(0xFFE2E8F0);
  static const text2Dark    = Color(0xFF94A3B8);

  // ── Status ───────────────────────────────
  static const green        = Color(0xFF4CAF81);
  static const pink         = Color(0xFFFF6B9D);
  static const red          = Color(0xFFE53935);

  // ── Theme-aware helper methods ────────────
  /// Context वापरून current theme चे bg color द्या
  static Color bgOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgDark : bg;

  static Color cardOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardDark : card;

  static Color textOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textDark : text;

  static Color text2Of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? text2Dark : text2;

  static Color progressBarBgOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? progressBarBgDark
          : progressBarBg;
}