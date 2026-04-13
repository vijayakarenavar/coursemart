/// Reset Password Screen
/// ✅ Dark Mode | ✅ Responsive | ✅ Safe Area | ✅ Landscape
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../utils/error_handler.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().resetPassword(email: widget.email, otp: widget.otp, newPassword: _newPwdCtrl.text);
      if (!mounted) return;
      showSuccessSnackBar(context, 'Password reset successfully! Please login.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      appBar: AppBar(
        title: const Text('Reset Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: isLandscape ? _buildLandscape() : _buildPortrait(),
        ),
      ),
    );
  }

  Widget _buildPortrait() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildSectionLabel('New Password'),
        _buildFieldsCard(),
        const SizedBox(height: 24),
        _buildResetButton(),
        const SizedBox(height: 40),
      ],
    ),
  );

  Widget _buildLandscape() => Row(
    children: [
      Expanded(child: SingleChildScrollView(child: _buildHeader())),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('New Password'),
              _buildFieldsCard(),
              const SizedBox(height: 24),
              _buildResetButton(),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 28, 16, 36),
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
    ),
    child: Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AppColors.cyan, AppColors.cyanDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        const Text('Set New Password', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 6),
        Text('Create a strong password\nfor your account.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), height: 1.65)),
      ],
    ),
  );

  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
    child: Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2Of(context), letterSpacing: 0.9)),
  );

  Widget _buildFieldsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _passwordField(controller: _newPwdCtrl, label: 'New Password', hint: 'Enter new password', iconBg: const Color(0xFFE6F1FB), iconColor: const Color(0xFF378ADD), obscure: _hideNew, onToggle: () => setState(() => _hideNew = !_hideNew), action: TextInputAction.next, validator: (v) { if (v == null || v.isEmpty) return 'New password is required'; if (v.length < 6) return 'Minimum 6 characters required'; return null; }, showDivider: true),
          _passwordField(controller: _confirmPwdCtrl, label: 'Confirm Password', hint: 'Re-enter new password', iconBg: const Color(0xFFEAF3DE), iconColor: AppColors.green, obscure: _hideConfirm, onToggle: () => setState(() => _hideConfirm = !_hideConfirm), action: TextInputAction.done, validator: (v) { if (v == null || v.isEmpty) return 'Please confirm your password'; if (v != _newPwdCtrl.text) return 'Passwords do not match'; return null; }, onSubmitted: (_) => _handleReset(), showDivider: false),
        ],
      ),
    );
  }

  Widget _passwordField({required TextEditingController controller, required String label, required String hint, required Color iconBg, required Color iconColor, required bool obscure, required VoidCallback onToggle, required TextInputAction action, required String? Function(String?) validator, bool showDivider = true, void Function(String)? onSubmitted}) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.lock_outline, color: iconColor, size: 17)),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: controller, obscureText: obscure, textInputAction: action, onFieldSubmitted: onSubmitted, validator: validator,
                style: TextStyle(fontSize: 13.5, color: AppColors.textOf(context)),
                decoration: InputDecoration(
                  labelText: label, labelStyle: TextStyle(fontSize: 11, color: AppColors.text2Of(context), fontWeight: FontWeight.w500),
                  hintText: hint, hintStyle: TextStyle(fontSize: 12, color: AppColors.text2Of(context).withOpacity(0.6)),
                  border: InputBorder.none, isDense: true,
                  suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppColors.text2Of(context)), onPressed: onToggle, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ),
              ),
            ),
          ],
        ),
      ),
      if (showDivider) Divider(height: 1, thickness: 0.5, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.08) : const Color(0xFFECF2F8), indent: 66, endIndent: 16),
    ],
  );

  Widget _buildResetButton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: GestureDetector(
      onTap: _isLoading ? null : _handleReset,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.cyan, AppColors.cyanDark]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.lock_reset_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('Reset Password  →', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))]),
        ),
      ),
    ),
  );
}