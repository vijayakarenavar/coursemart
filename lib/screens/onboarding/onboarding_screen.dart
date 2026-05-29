/// Onboarding Screen
///
/// ✅ Dark Mode / Light Mode support
/// ✅ Responsive layout (phone + tablet)
/// ✅ SharedPreferences — एकदाच दाखवतो
/// ✅ App theme शी match
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_colors.dart';
import '../auth/login_screen.dart';

// ── Onboarding Data ───────────────────────────────────────────────────────────
class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });
}

const List<_OnboardingData> _pages = [
  _OnboardingData(
    icon: Icons.school_rounded,
    title: 'Welcome to CourseMart',
    subtitle:
    'Your complete student portal — access all your courses, lectures, and study material in one place.',
    iconColor: AppColors.cyan,
  ),
  _OnboardingData(
    icon: Icons.play_circle_rounded,
    title: 'Learn at Your Own Pace',
    subtitle:
    'Watch video lectures, download notes and study material — anytime, anywhere.',
    iconColor: Color(0xFF4CAF81),
  ),
  _OnboardingData(
    icon: Icons.verified_rounded,
    title: 'Earn Your Certificates',
    subtitle:
    'Complete your courses and download your official certificates directly from the app.',
    iconColor: Color(0xFFFF6B9D),
  ),
];

// ── Onboarding Screen ─────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animController.reset();
    _animController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _currentPage == _pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
        isDark ? AppColors.bgDark : AppColors.bg,
        systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgOf(context),
        body: SafeArea(
          child: Column(
            children: [
              // ── Skip Button ──
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 20),
                  child: isLast
                      ? const SizedBox(height: 36)
                      : TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.text2Of(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Page View ──
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(
                      data: _pages[index],
                      fadeAnim: _fadeAnim,
                      slideAnim: _slideAnim,
                      isDark: isDark,
                    );
                  },
                ),
              ),

              // ── Dots + Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                            (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? AppColors.cyan
                                : AppColors.text2Of(context).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Next / Get Started Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isDark ? AppColors.cyan : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                  ? Icons.login_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single Onboarding Page ────────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final bool isDark;

  const _OnboardingPage({
    required this.data,
    required this.fadeAnim,
    required this.slideAnim,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: data.iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data.iconColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: data.iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.icon,
                      size: 52,
                      color: data.iconColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textDark : AppColors.text,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.text2Dark : AppColors.text2,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper: Check if onboarding is done ──────────────────────────────────────
Future<bool> isOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_done') ?? false;
}