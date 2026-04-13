/// App Dialogs & Snackbars
///
/// Centralized utility for all dialog boxes and snackbar messages.
/// All colors follow AppColors theme — single file update करा, सगळं बदलतं.
///
/// Usage:
///   import '../../utils/app_dialogs.dart';
///
///   // Snackbars
///   AppDialogs.showSuccess(context, 'Profile saved!');
///   AppDialogs.showError(context, 'Something went wrong');
///   AppDialogs.showInfo(context, 'New lecture available');
///
///   // Dialogs
///   AppDialogs.showConfirm(context, title: '...', message: '...', onConfirm: () {});
///   AppDialogs.showLogout(context, onConfirm: () {});
///   AppDialogs.showLoading(context);
///   AppDialogs.hideLoading(context);
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDialogs {
  AppDialogs._();

  // ─────────────────────────────────────────────────────
  // SNACKBARS
  //
  // Duration + dismiss logic:
  //   Success  → 2.5s auto, no X  — quick positive confirm
  //   Info     → 3s auto, no X    — neutral, no action needed
  //   Warning  → 4s auto + X      — user ने वाचावे, dismiss option
  //   Error    → persistent + X   — user ने action घेईपर्यंत राहतो
  // ─────────────────────────────────────────────────────

  /// ✅ Success Snackbar
  /// Color: primary navy + cyan border — green odd वाटतो कारण app थीम navy+cyan आहे
  /// Duration: 2.5s auto — X button नाही, फक्त confirm
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.primary,
      borderColor: AppColors.cyan,
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.cyan,
      duration: const Duration(milliseconds: 2500),
      showDismiss: false,
    );
  }

  /// ❌ Error Snackbar
  /// Color: red — स्पष्ट error
  /// Duration: persistent (30s) — X button हवाच, user action पर्यंत राहतो
  static void showError(BuildContext context, String message) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.red,
      borderColor: const Color(0xFFFF8A80),
      icon: Icons.error_outline_rounded,
      iconColor: Colors.white,
      duration: const Duration(seconds: 30), // effectively persistent
      showDismiss: true,
    );
  }

  /// ℹ️ Info Snackbar
  /// Color: primaryLight + cyan border — neutral, थीमशी सुसंगत
  /// Duration: 3s auto — X button नाही
  static void showInfo(BuildContext context, String message) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.primaryLight,
      borderColor: AppColors.cyan.withOpacity(0.5),
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.cyan,
      duration: const Duration(seconds: 3),
      showDismiss: false,
    );
  }

  /// ⚠️ Warning Snackbar
  /// Color: primary navy + pink border — orange odd वाटतो, pink app थीम मध्येच आहे
  /// Duration: 4s + X button — user ने वाचावे
  static void showWarning(BuildContext context, String message) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.primary,
      borderColor: AppColors.pink,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.pink,
      duration: const Duration(seconds: 4),
      showDismiss: true,
    );
  }

  /// Internal snackbar builder
  static void _showSnackbar(
      BuildContext context, {
        required String message,
        required Color backgroundColor,
        required Color borderColor,
        required IconData icon,
        required Color iconColor,
        required Duration duration,
        required bool showDismiss,
      }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              if (showDismiss) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        // error persistent — swipe नको, X button ने dismiss
        // success/info — swipe नको (auto dismiss होतो)
        // warning — X आहे, swipe पण चालेल
        dismissDirection: showDismiss && backgroundColor == AppColors.primary
            ? DismissDirection.horizontal
            : DismissDirection.none,
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────────────

  /// 🔔 Confirm Dialog — हो/नाही decision साठी
  ///
  /// Example:
  /// ```dart
  /// AppDialogs.showConfirm(
  ///   context,
  ///   title: 'Delete Account',
  ///   message: 'Are you sure you want to delete your account?',
  ///   confirmText: 'Delete',
  ///   isDanger: true,
  ///   onConfirm: () { /* delete logic */ },
  /// );
  /// ```
  static Future<void> showConfirm(
      BuildContext context, {
        required String title,
        required String message,
        required VoidCallback onConfirm,
        String confirmText = 'Confirm',
        String cancelText = 'Cancel',
        bool isDanger = false,
      }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.text2,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.text2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(cancelText),
          ),
          // Confirm button
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppColors.red : AppColors.cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 🚪 Logout Confirm Dialog — logout साठी ready-made dialog
  ///
  /// Example:
  /// ```dart
  /// AppDialogs.showLogout(context, onConfirm: () {
  ///   ref.read(authProvider.notifier).logout();
  /// });
  /// ```
  static Future<void> showLogout(
      BuildContext context, {
        required VoidCallback onConfirm,
      }) async {
    await showConfirm(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Stay',
      isDanger: true,
      onConfirm: onConfirm,
    );
  }

  /// 🔑 Change Password Confirm Dialog
  static Future<void> showChangePassword(
      BuildContext context, {
        required VoidCallback onConfirm,
      }) async {
    await showConfirm(
      context,
      title: 'Change Password',
      message: 'Are you sure you want to change your password?',
      confirmText: 'Yes, Change',
      onConfirm: onConfirm,
    );
  }

  /// ⏳ Loading Dialog — API call चालू असताना
  ///
  /// ✅ Fix: rootNavigator: true वापरतो — त्यामुळे hideLoading नक्की काम करतो
  ///
  /// Example:
  /// ```dart
  /// AppDialogs.showLoading(context);
  /// await apiService.login(...);
  /// AppDialogs.hideLoading(context);
  /// ```
  static void showLoading(BuildContext context, {String message = 'Please wait...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      // rootNavigator: true — nested navigators असले तरी root वर dialog जातो
      // त्यामुळे hideLoading ला पण rootNavigator: true द्यावे लागतो
      useRootNavigator: true,
      builder: (ctx) => PopScope(
        // Back button ने dismiss होऊ नये
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Loading dialog बंद करा
  ///
  /// showLoading सारखाच useRootNavigator: true — नाहीतर dialog बंद होत नाही
  static void hideLoading(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  /// ℹ️ Info / Alert Dialog — simple message दाखवण्यासाठी
  ///
  /// Example:
  /// ```dart
  /// AppDialogs.showAlert(
  ///   context,
  ///   title: 'Session Expired',
  ///   message: 'Please login again to continue.',
  /// );
  /// ```
  static Future<void> showAlert(
      BuildContext context, {
        required String title,
        required String message,
        String buttonText = 'OK',
        VoidCallback? onDismiss,
      }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cyanLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.cyan,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.text2,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// 🔴 Error Dialog — API error साठी session expired इत्यादी
  ///
  /// onDismiss callback logout / navigate साठी वापरा
  static Future<void> showErrorDialog(
      BuildContext context, {
        required String title,
        required String message,
        String buttonText = 'OK',
        VoidCallback? onDismiss,
      }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.text2,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}