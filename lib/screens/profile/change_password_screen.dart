/// Change Password Screen
/// ✅ Dark Mode | ✅ Responsive | ✅ Safe Area | ✅ Landscape
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
  final _formKey = GlobalKey<FormState>();
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _hideCurrentPwd = true;
  bool _hideNewPwd = true;
  bool _hideConfirmPwd = true;
  bool _isLoading = false;

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
      final msg = await context.read<AuthProvider>().changePassword(currentPassword: _currentPwdCtrl.text, newPassword: _newPwdCtrl.text);
      if (!mounted) return;
      showSuccessSnackBar(context, msg);
      _currentPwdCtrl.clear(); _newPwdCtrl.clear(); _confirmPwdCtrl.clear();
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      appBar: AppBar(
        title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
        _buildSectionLabel('Password Fields'),
        _buildFieldsCard(),
        const SizedBox(height: 24),
        _buildSubmitButton(),
        _buildCancelButton(),
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
              _buildSectionLabel('Password Fields'),
              _buildFieldsCard(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
    ),
    child: Column(
      children: [
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AppColors.cyan, AppColors.cyanDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5))],
          ),
          child: const Icon(Icons.lock_outline, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 14),
        const Text('Update Your Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Keep your account safe and secure', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
      ],
    ),
  );

  Widget _buildSectionLabel(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
    child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2Of(context), letterSpacing: 0.9)),
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
          _passwordField(controller: _currentPwdCtrl, label: 'Current Password', hint: 'Enter current password', iconBg: AppColors.cyanLight, iconColor: AppColors.cyanDark, obscure: _hideCurrentPwd, onToggle: () => setState(() => _hideCurrentPwd = !_hideCurrentPwd), action: TextInputAction.next, validator: (v) => (v == null || v.isEmpty) ? 'Current password is required' : null, showDivider: true),
          _passwordField(controller: _newPwdCtrl, label: 'New Password', hint: 'Enter new password', iconBg: const Color(0xFFE6F1FB), iconColor: const Color(0xFF378ADD), obscure: _hideNewPwd, onToggle: () => setState(() => _hideNewPwd = !_hideNewPwd), action: TextInputAction.next, validator: (v) { if (v == null || v.isEmpty) return 'New password is required'; if (v.length < 6) return 'Password must be at least 6 characters'; return null; }, showDivider: true),
          _passwordField(controller: _confirmPwdCtrl, label: 'Confirm New Password', hint: 'Re-enter new password', iconBg: const Color(0xFFEAF3DE), iconColor: AppColors.green, obscure: _hideConfirmPwd, onToggle: () => setState(() => _hideConfirmPwd = !_hideConfirmPwd), action: TextInputAction.done, validator: (v) { if (v == null || v.isEmpty) return 'Please confirm your password'; if (v != _newPwdCtrl.text) return 'Passwords do not match'; return null; }, onSubmitted: (_) => _handleChangePassword(), showDivider: false),
        ],
      ),
    );
  }

  Widget _passwordField({required TextEditingController controller, required String label, required String hint, required Color iconBg, required Color iconColor, required bool obscure, required VoidCallback onToggle, required TextInputAction action, required String? Function(String?) validator, bool showDivider = true, void Function(String)? onSubmitted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
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
        if (showDivider) Divider(height: 1, thickness: 0.5, color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFECF2F8), indent: 66, endIndent: 16),
      ],
    );
  }

  Widget _buildSubmitButton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: GestureDetector(
      onTap: _isLoading ? null : _handleChangePassword,
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
              : Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.lock_outline, color: Colors.white, size: 17), SizedBox(width: 8), Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))]),
        ),
      ),
    ),
  );

  Widget _buildCancelButton() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text2Of(context),
          side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.15) : const Color(0xFFE0E8F0), width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}