/// Forgot Password Screen
/// ✅ Dark Mode | ✅ Responsive | ✅ Safe Area | ✅ Landscape
library;

import 'package:coursemart_app/screens/auth/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../utils/error_handler.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // token directly मिळतो — OTP screen नाही
      final token = await context
          .read<AuthProvider>()
          .forgotPassword(email: _emailController.text.trim());

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            token: token, // email नाही, token पाठवतो
          ),
        ),
      );
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
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final hp = isTablet ? 24.0 : 14.0;

    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      appBar: AppBar(
        title: const Text('Forgot Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: isLandscape
              ? _buildLandscape(context, hp)
              : _buildPortrait(context, hp),
        ),
      ),
    );
  }

  // ── Portrait ──────────────────────────────────────────────────────────────
  Widget _buildPortrait(BuildContext context, double hp) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 28),
          _buildSectionLabel('Email Address', hp),
          _buildEmailCard(context, hp),
          const SizedBox(height: 28),
          _buildSendOtpButton(hp),
          const SizedBox(height: 14),
          _buildBackToLogin(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Landscape: header left, form right ───────────────────────────────────
  Widget _buildLandscape(BuildContext context, double hp) {
    return Row(
      children: [
        Expanded(child: SingleChildScrollView(child: _buildHeader())),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(hp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Email Address', 0),
                _buildEmailCard(context, 0),
                const SizedBox(height: 24),
                _buildSendOtpButton(0),
                const SizedBox(height: 14),
                _buildBackToLogin(),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
          child: const Icon(Icons.mail_outline_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        const Text('Reset Your Password', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 6),
        Text(
          'Enter your registered email.\nWe\'ll send a password reset link to your account.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), height: 1.65),
        ),
      ],
    ),
  );

  Widget _buildSectionLabel(String label, double hp) => Padding(
    padding: EdgeInsets.fromLTRB(hp == 0 ? 0 : 18, 0, 18, 10),
    child: Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2Of(context), letterSpacing: 0.9)),
  );

  Widget _buildEmailCard(BuildContext context, double hp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hp == 0 ? 0 : 14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.cyanLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.email_outlined, color: AppColors.cyanDark, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSendOtp(),
                style: TextStyle(fontSize: 13.5, color: AppColors.textOf(context)),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(fontSize: 11, color: AppColors.text2Of(context), fontWeight: FontWeight.w500),
                  hintText: 'Enter your registered email',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.text2Of(context).withOpacity(0.6)),
                  border: InputBorder.none,
                  isDense: true,
                ),
                validator: ValidationHelper.validateEmail,
                autofillHints: const [AutofillHints.email],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendOtpButton(double hp) => Padding(
    padding: EdgeInsets.symmetric(horizontal: hp == 0 ? 0 : 14),
    child: GestureDetector(
      onTap: _isLoading ? null : _handleSendOtp,
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
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.send_rounded, color: Colors.white, size: 17),
              SizedBox(width: 8),
              Text('Send Reset Link  →', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildBackToLogin() => Center(
    child: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Text.rich(
        TextSpan(
          text: 'Remember your password? ',
          style: TextStyle(fontSize: 12, color: AppColors.text2Of(context)),
          children: const [TextSpan(text: 'Sign In', style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700))],
        ),
      ),
    ),
  );
}