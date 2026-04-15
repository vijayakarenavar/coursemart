/// OTP Verify Screen
/// ✅ Dark Mode | ✅ Responsive | ✅ Safe Area | ✅ Landscape
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../utils/error_handler.dart';
import '../../providers/auth_provider.dart';
import 'reset_password_screen.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 60;

  final List<TextEditingController> _ctrl = List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(_otpLength, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _timer = _resendSeconds;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus[0].requestFocus());
  }

  @override
  void dispose() {
    _countdown?.cancel();
    for (final c in _ctrl) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = _resendSeconds;
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timer == 0) { t.cancel(); } else { setState(() => _timer--); }
    });
  }

  String get _otp => _ctrl.map((c) => c.text).join();

  void _onDigitChanged(String val, int index) {
    if (val.length == 1 && index < _otpLength - 1) _focus[index + 1].requestFocus();
    setState(() {});
    if (_ctrl.every((c) => c.text.isNotEmpty)) _handleVerify();
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && _ctrl[index].text.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
      _ctrl[index - 1].clear();
    }
  }

  Future<void> _handleVerify() async {
    final otp = _otp;
    if (otp.length < _otpLength) { showErrorSnackBar(context, 'Please enter all 6 digits'); return; }
    if (_isVerifying) return;
    setState(() => _isVerifying = true);
    try {
      await context.read<AuthProvider>().verifyForgotPasswordOtp(email: widget.email, otp: otp);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: widget.email, otp: otp)));
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, getErrorMessage(e));
      for (final c in _ctrl) {
        c.clear();
      }
      setState(() {});
      _focus[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (_timer > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await context.read<AuthProvider>().sendForgotPasswordOtp(email: widget.email);
      if (!mounted) return;
      showSuccessSnackBar(context, 'OTP resent to ${widget.email}');
      for (final c in _ctrl) {
        c.clear();
      }
      setState(() {});
      _focus[0].requestFocus();
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      appBar: AppBar(
        title: const Text('Verify OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: isLandscape ? _buildLandscape() : _buildPortrait(),
      ),
    );
  }

  Widget _buildPortrait() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildSectionLabel('Enter OTP'),
          _buildOtpBoxes(),
          const SizedBox(height: 10),
          _buildResendRow(),
          const SizedBox(height: 32),
          _buildVerifyButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLandscape() {
    return Row(
      children: [
        Expanded(child: SingleChildScrollView(child: _buildHeader())),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Enter OTP'),
                _buildOtpBoxes(),
                const SizedBox(height: 10),
                _buildResendRow(),
                const SizedBox(height: 24),
                _buildVerifyButton(),
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
          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        const Text('Check Your Email', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 6),
        Text('We sent a 6-digit OTP to', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 4),
        Text(widget.email, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.cyan)),
      ],
    ),
  );

  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
    child: Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2Of(context), letterSpacing: 0.9)),
  );

  Widget _buildOtpBoxes() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLength, (i) {
        final filled = _ctrl[i].text.isNotEmpty;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SizedBox(
          width: 48, height: 56,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (e) => _onKeyEvent(e, i),
            child: TextFormField(
              controller: _ctrl[i],
              focusNode: _focus[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: filled ? AppColors.primary : AppColors.text2Of(context)),
              onChanged: (val) => _onDigitChanged(val, i),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: filled ? AppColors.cyanLight : AppColors.cardOf(context),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: filled ? AppColors.cyan : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)), width: filled ? 1.8 : 1.2),
                ),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cyan, width: 2)),
              ),
            ),
          ),
        );
      }),
    ),
  );

  Widget _buildResendRow() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_timer > 0) ...[
          Icon(Icons.timer_outlined, size: 14, color: AppColors.text2Of(context)),
          const SizedBox(width: 4),
          Text('Resend OTP in ${_timer}s', style: TextStyle(fontSize: 12, color: AppColors.text2Of(context))),
        ] else
          GestureDetector(
            onTap: _isResending ? null : _handleResend,
            child: Row(
              children: [
                _isResending
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan)))
                    : const Icon(Icons.refresh_rounded, size: 15, color: AppColors.cyan),
                const SizedBox(width: 4),
                Text(_isResending ? 'Sending...' : 'Resend OTP', style: const TextStyle(fontSize: 12, color: AppColors.cyan, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _buildVerifyButton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: GestureDetector(
      onTap: _isVerifying ? null : _handleVerify,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.cyan, AppColors.cyanDark]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: _isVerifying
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Verify OTP  →', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    ),
  );
}