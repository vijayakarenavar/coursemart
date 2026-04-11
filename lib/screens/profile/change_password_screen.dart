/// Change Password Screen - CourseMart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/error_handler.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl     = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _hideCurrentPwd = true;
  bool _hideNewPwd     = true;
  bool _hideConfirmPwd = true;
  bool _isLoading      = false;

  @override
  void dispose() {
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final msg = await context.read<AuthProvider>().changePassword(
        currentPassword: _currentPwdCtrl.text,
        newPassword: _newPwdCtrl.text,
      );
      if (!mounted) return;
      showSuccessSnackBar(context, msg);
      _currentPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSectionLabel('Password Fields'),
                _buildFieldsCard(),
                const SizedBox(height: 20),
                _buildSubmitButton(),
                _buildCancelButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dark navy header with lock icon
  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.only(
        bottomLeft:  Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
    ),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyan.withOpacity(0.15),
            border: Border.all(
              color: AppColors.cyan.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.lock_outline,
            color: AppColors.cyan,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Update Your Password',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Keep your account safe and secure',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    ),
  );

  Widget _buildSectionLabel(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.text2,
        letterSpacing: 0.8,
      ),
    ),
  );

  /// White card with all 3 password fields
  Widget _buildFieldsCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        _passwordField(
          controller: _currentPwdCtrl,
          label: 'Current Password',
          hint: 'Enter current password',
          iconBg: AppColors.cyanLight,
          iconColor: AppColors.cyanDark,
          obscure: _hideCurrentPwd,
          onToggle: () => setState(() => _hideCurrentPwd = !_hideCurrentPwd),
          action: TextInputAction.next,
          validator: (v) =>
          (v == null || v.isEmpty)
              ? 'Current password is required'
              : null,
          showDivider: true,
        ),
        _passwordField(
          controller: _newPwdCtrl,
          label: 'New Password',
          hint: 'Enter new password',
          iconBg: const Color(0xFFE6F1FB),
          iconColor: const Color(0xFF378ADD),
          obscure: _hideNewPwd,
          onToggle: () => setState(() => _hideNewPwd = !_hideNewPwd),
          action: TextInputAction.next,
          validator: (v) {
            if (v == null || v.isEmpty) return 'New password is required';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
          showDivider: true,
        ),
        _passwordField(
          controller: _confirmPwdCtrl,
          label: 'Confirm New Password',
          hint: 'Re-enter new password',
          iconBg: const Color(0xFFEAF3DE),
          iconColor: AppColors.green,
          obscure: _hideConfirmPwd,
          onToggle: () => setState(() => _hideConfirmPwd = !_hideConfirmPwd),
          action: TextInputAction.done,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _newPwdCtrl.text) return 'Passwords do not match';
            return null;
          },
          onSubmitted: (_) => _handleChangePassword(),
          showDivider: false,
        ),
      ],
    ),
  );

  /// Reusable password field row inside card
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color iconBg,
    required Color iconColor,
    required bool obscure,
    required VoidCallback onToggle,
    required TextInputAction action,
    required String? Function(String?) validator,
    bool showDivider = true,
    void Function(String)? onSubmitted,
  }) =>
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.lock_outline, color: iconColor, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    obscureText: obscure,
                    textInputAction: action,
                    onFieldSubmitted: onSubmitted,
                    validator: validator,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.text,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        color: AppColors.text2,
                      ),
                      hintText: hint,
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.text2,
                        ),
                        onPressed: onToggle,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(
              height: 1, thickness: 0.5,
              color: Color(0xFFE8F0F8),
              indent: 60, endIndent: 14,
            ),
        ],
      );

  /// Submit button
  Widget _buildSubmitButton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleChangePassword,
        icon: _isLoading
            ? const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : const Icon(Icons.lock_outline, size: 17),
        label: Text(
          _isLoading ? 'Updating...' : 'Change Password',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  );

  /// Cancel button
  Widget _buildCancelButton() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text2,
          side: const BorderSide(color: Color(0xFFE8F0F8)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Cancel', style: TextStyle(fontSize: 13)),
      ),
    ),
  );
}