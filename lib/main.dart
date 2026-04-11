/// CourseMart Student App
///
/// Main entry point for the CourseMart application.
/// Initializes environment, services, providers, and handles auth flow.
library;

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
import 'utils/app_colors.dart';

/// App entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar & nav bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load environment variables from .env file
  await loadEnvironment();

  // Initialize API service with Dio interceptors
  ApiService().init();

  // Initialize cache manager
  await CacheManager().init();

  runApp(const CourseMartApp());
}

/// CourseMart Application Widget
class CourseMartApp extends StatelessWidget {
  const CourseMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider - manages authentication state
        ChangeNotifierProvider(
          create: (_) {
            final authProvider = AuthProvider();

            // Set up unauthorized handler for auto-logout
            ApiService().onUnauthorized = () {
              authProvider.handleUnauthorized();
            };

            // Initialize auth state (check token, fetch profile)
            authProvider.init();

            return authProvider;
          },
        ),

        // Course Provider - manages courses list
        ChangeNotifierProvider(create: (_) => CourseProvider()),

        // Lecture Provider - manages lectures for selected course
        ChangeNotifierProvider(create: (_) => LectureProvider()),
      ],
      child: MaterialApp(
        title: 'CourseMart',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const AuthWrapper(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      // Primary color scheme
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bg,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.cyan,
      ),

      // App bar theme
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

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // Elevated button theme
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

      // Outlined button theme
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

      // Input decoration theme
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

      // Text theme
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

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.text2),
    );
  }
}

/// Authentication Wrapper
///
/// Listens to auth state and navigates to appropriate screen:
/// - Checking: Shows loading screen
/// - Authenticated: Shows dashboard
/// - Unauthenticated: Shows login screen
/// - Error: Shows login screen with option to retry
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
          // ✅ हे add करा
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<CourseProvider>().fetchCourses();
            });
            return const DashboardScreen();

          case AuthStatus.unauthenticated:
          // ✅ हे add करा - logout झाल्यावर CourseProvider clear करा
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<CourseProvider>().clearData();
            });
            return const LoginScreen();

          case AuthStatus.error:
            return const LoginScreen();
        }
      },
    );
  }
}

/// Loading Screen
///
/// Displayed while checking authentication on app startup
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            children: [
              // Top hero — same as login
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    // Subtle cyan glow
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.cyan.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // NOVAA logo
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'NO',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                TextSpan(
                                  text: 'V',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.cyan,
                                    letterSpacing: -1,
                                  ),
                                ),
                                TextSpan(
                                  text: 'AA',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'CourseMart Student Portal',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom card — loading indicator
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Cyan loading indicator
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.cyan,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Loading CourseMart...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}