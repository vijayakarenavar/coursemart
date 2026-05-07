/// Login Screen
/// ✅ Dark Mode | ✅ Responsive | ✅ Safe Area | ✅ Landscape
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/error_handler.dart';
import 'forgot_password_screen.dart';
import '../../services/secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        email: email,
        password: password,
      );
      if (!mounted) return;
      if (success) {
        // ✅ WebView auto-login साठी credentials save करा
        await SecureStorage().saveCredentials(email: email, password: password);
      } else {
        showErrorSnackBar(context, authProvider.errorMessage ?? 'Login failed');
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.bgOf(context),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: isLandscape
              ? _buildLandscape(context)
              : _buildPortrait(context),
        ),
      ),
    );
  }

  // ── Portrait Layout ──────────────────────────────────────────────────────
  Widget _buildPortrait(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 2, child: _buildLogoSection()),
        Expanded(flex: 3, child: _buildFormCard(context)),
      ],
    );
  }

  // ── Landscape Layout ─────────────────────────────────────────────────────
  Widget _buildLandscape(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildLogoSection()),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              bottomLeft: Radius.circular(32),
            ),
            child: _buildFormCard(context),
          ),
        ),
      ],
    );
  }

  // ── Logo Section ─────────────────────────────────────────────────────────
  Widget _buildLogoSection() {
    return Stack(
      children: [
        Positioned(
          top: -40, right: -40,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.cyan.withOpacity(0.18), Colors.transparent],
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: 'NO', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                    TextSpan(text: 'V', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.cyan, letterSpacing: -1)),
                    TextSpan(text: 'AA', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CourseMart Student Portal',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5), letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Form Card ────────────────────────────────────────────────────────────
  Widget _buildFormCard(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final hp = isTablet ? 36.0 : 28.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgOf(context),
        borderRadius: isLandscape
            ? const BorderRadius.only(topLeft: Radius.circular(32), bottomLeft: Radius.circular(32))
            : const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hp, 36, hp, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textOf(context))),
              const SizedBox(height: 4),
              Text('Sign in to continue learning', style: TextStyle(fontSize: 13, color: AppColors.text2Of(context))),
              const SizedBox(height: 28),

              _buildFieldLabel('EMAIL ADDRESS'),
              const SizedBox(height: 8),
              _buildEmailField(context),
              const SizedBox(height: 18),

              _buildFieldLabel('PASSWORD'),
              const SizedBox(height: 8),
              _buildPasswordField(context),
              const SizedBox(height: 14),

              _buildForgotPassword(context),
              const SizedBox(height: 24),

              _buildLoginButton(),
              const SizedBox(height: 18),

              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(fontSize: 12, color: AppColors.text2Of(context)),
                    children: const [
                      TextSpan(text: 'Contact College', style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2Of(context), letterSpacing: 0.8),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(fontSize: 14, color: AppColors.textOf(context)),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.cardOf(context),
        suffixIcon: Icon(Icons.email_outlined, color: AppColors.text2Of(context), size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cyan, width: 1.8)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.red, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.red, width: 1.8)),
      ),
      validator: ValidationHelper.validateEmail,
      autofillHints: const [AutofillHints.email],
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      style: TextStyle(fontSize: 15, color: AppColors.textOf(context)),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.cardOf(context),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.text2Of(context), size: 18),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cyan, width: 1.8)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.red, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.red, width: 1.8)),
      ),
      validator: ValidationHelper.validatePassword,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) => _handleLogin(),
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
        child: const Text('Forgot Password?', style: TextStyle(fontSize: 13, color: AppColors.cyan, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.cyan, AppColors.cyanDark]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : const Text('Sign In  →', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ),
      ),
    );
  }
}