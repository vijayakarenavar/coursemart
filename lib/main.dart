/// CourseMart Student App
///
/// ✅ Dark Mode + Light Mode
/// ✅ Responsive (MediaQuery based)
/// ✅ Safe Area
/// ✅ Landscape support
library;

import 'package:coursemart_app/providers/certificate_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/env_loader.dart';
import 'services/api_service.dart';
import 'utils/cache_manager.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/lecture_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait + Landscape दोन्ही allow करा
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await loadEnvironment();
  ApiService().init();
  await CacheManager().init();

  runApp(const CourseMartApp());
}

class CourseMartApp extends StatelessWidget {
  const CourseMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final authProvider = AuthProvider();
            ApiService().onUnauthorized = () {
              authProvider.handleUnauthorized();
            };
            authProvider.init();
            return authProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => LectureProvider()),
        ChangeNotifierProvider(create: (_) => CertificateProvider()),
      ],
      child: MaterialApp(
        title: 'CourseMart',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        home: const AuthWrapper(),
      ),
    );
  }

  // ── Light Theme ──────────────────────────────────────────────────────
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bg,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.cyan,
        surface: AppColors.card,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.black.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: const TextStyle(color: AppColors.text2, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.text2, fontSize: 14),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.text),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.text2),
      ),

      iconTheme: const IconThemeData(color: AppColors.text2),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgDark,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.cyan,
        surface: AppColors.cardDark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cyan,
          side: const BorderSide(color: AppColors.cyan),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: const TextStyle(color: AppColors.text2Dark, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.text2Dark, fontSize: 14),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.textDark),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.text2Dark),
      ),

      iconTheme: const IconThemeData(color: AppColors.text2Dark),
    );
  }
}

// ── Auth Wrapper ─────────────────────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.status) {
          case AuthStatus.checking:
            return const LoadingScreen();

          case AuthStatus.authenticated:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<CourseProvider>().fetchCourses();
            });
            return const DashboardScreen();

          case AuthStatus.unauthenticated:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<CourseProvider>().clearData();
            });
            // ✅ Onboarding — फक्त पहिल्यांदाच दाखवतो
            return FutureBuilder<bool>(
              future: isOnboardingDone(),
              builder: (context, snapshot) {
                // Loading असताना blank screen नको
                if (!snapshot.hasData) return const LoadingScreen();
                // Onboarding झाली असेल तर login
                if (snapshot.data == true) return const LoginScreen();
                // पहिल्यांदा — onboarding दाखव
                return const OnboardingScreen();
              },
            );

          case AuthStatus.error:
            return const LoginScreen();
        }
      },
    );
  }
}

// ── Loading Screen ────────────────────────────────────────────────────────────
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Landscape साठी orientation detect करा
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.bgDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: isLandscape
              ? _buildLandscapeLayout(context)
              : _buildPortraitLayout(context),
        ),
      ),
    );
  }

  // ── Portrait Layout ──
  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 2, child: _buildLogo()),
        Expanded(flex: 3, child: _buildLoadingCard(context)),
      ],
    );
  }

  // ── Landscape Layout ──
  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildLogo()),
        Expanded(child: _buildLoadingCard(context)),
      ],
    );
  }

  Widget _buildLogo() {
    return Stack(
      children: [
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
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
              Image.asset(
                'assets/images/novaa.png',
                height: 90,
              ),
              const SizedBox(height: 8),
              Text(
                'CourseMart Student Portal',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgOf(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading CourseMart...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text2Of(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}