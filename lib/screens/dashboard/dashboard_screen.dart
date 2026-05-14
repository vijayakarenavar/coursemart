/// Dashboard Screen
///
/// ✅ Dark Mode / Light Mode support
/// ✅ Responsive layout (phone + tablet)
/// ✅ Landscape view proper
/// ✅ Safe Area handled
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/certificate.dart';
import '../../providers/certificate_provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/empty_state.dart';
import '../course/course_details_screen.dart';
import '../profile/profile_screen.dart';
import '../../models/course.dart';
import '../../config/feature_flags.dart';
import '../certificates/certificate_view_screen.dart';

/// Responsive helper
class _Responsive {
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static double horizontalPadding(BuildContext context) =>
      isTablet(context) ? 24.0 : 16.0;

  static int gridColumns(BuildContext context) =>
      isTablet(context) ? 4 : 2;

  static double gridAspectRatio(BuildContext context) =>
      isTablet(context) ? 1.4 : 1.5;
}

// ── Dashboard Shell ───────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    const _HomeTab(),
    const _CoursesTab(),
    if (FeatureFlags.showProgressTab) const _ProgressTab(),
    const _CertificatesTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = _Responsive.isLandscape(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor:
        _currentIndex == 0 ? AppColors.primary : Colors.transparent,
        statusBarIconBrightness:
        _currentIndex == 0 ? Brightness.light : (isDark ? Brightness.light : Brightness.dark),
        systemNavigationBarColor:
        isDark ? AppColors.cardDark : AppColors.card,
        systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgOf(context),
        body: isLandscape
            ? Row(
          children: [
            _buildSideNav(context),
            Expanded(child: _screens[_currentIndex]),
          ],
        )
            : _screens[_currentIndex],
        bottomNavigationBar:
        isLandscape ? null : _buildBottomNav(context, isDark),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSideNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      right: false,
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _navItems(context, vertical: true),
        ),
      ),
    );
  }

  List<Widget> _navItems(BuildContext context, {bool vertical = false}) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.menu_book_rounded, 'Courses'),
      if (FeatureFlags.showProgressTab)
        (Icons.bar_chart_rounded, 'Progress'),
      (Icons.workspace_premium_rounded, 'Certs'),
    ];

    return items.asMap().entries.map((entry) {
      final idx = entry.key;
      final (icon, label) = entry.value;
      return _NavItem(
        icon: icon,
        label: label,
        active: _currentIndex == idx,
        vertical: vertical,
        onTap: () => setState(() => _currentIndex = idx),
      );
    }).toList();
  }
}

// ── Nav Item ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool vertical;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: vertical
            ? const EdgeInsets.symmetric(vertical: 6, horizontal: 8)
            : EdgeInsets.zero,
        padding: vertical
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.cyanLight : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.cyan : AppColors.text2Of(context),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.cyan : AppColors.text2Of(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HOME TAB ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hp = _Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Consumer<CourseProvider>(
              builder: (context, courseProvider, _) {
                return RefreshIndicator(
                  onRefresh: () => courseProvider.refresh(),
                  color: AppColors.cyan,
                  child: _buildPortraitContent(context, courseProvider, hp),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitContent(
      BuildContext context, CourseProvider cp, double hp) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildWelcomeCard(context, hp),
        SizedBox(height: hp),
        _buildStatGrid(context, cp, hp),
        SizedBox(height: hp),
        _buildProgressCard(context, cp, hp),
        SizedBox(height: hp),
        _buildCourseList(context, cp, hp),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Row(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Course',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'Mart',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cyan,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(width: 12),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final initial = auth.studentName.isNotEmpty
                      ? auth.studentName[0].toUpperCase()
                      : 'S';
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.cyan, AppColors.cyanDark],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, double hp) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hp, hp, hp, 0),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.cyan.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👋', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        text: 'Welcome,\n',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text: '${auth.studentName}!',
                            style: const TextStyle(color: AppColors.cyan),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Continue learning where you left off',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatGrid(
      BuildContext context, CourseProvider cp, double hp) {
    final enrolled = cp.courseCount;
    final completed = cp.completedLecturesCount;
    final remaining = cp.remainingLecturesCount;
    final overallPct = '${(cp.overallProgress * 100).toInt()}%';
    final columns = _Responsive.gridColumns(context);
    final aspectRatio = _Responsive.gridAspectRatio(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: aspectRatio,
        children: [
          _StatCard(
            icon: Icons.menu_book_rounded,
            iconBg: AppColors.primary,
            number: '$enrolled',
            label: 'Enrolled',
          ),
          _StatCard(
            icon: Icons.check_circle_rounded,
            iconBg: AppColors.green,
            number: '$completed',
            label: 'Completed',
          ),
          _StatCard(
            icon: Icons.access_time_rounded,
            iconBg: AppColors.pink,
            number: '$remaining',
            label: 'Remaining',
          ),
          _StatCard(
            icon: Icons.bar_chart_rounded,
            iconBg: AppColors.cyan,
            number: overallPct,
            label: 'Progress',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      BuildContext context, CourseProvider cp, double hp) {
    final pct = (cp.overallProgress * 100).toInt();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Learning Progress',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOf(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: cp.overallProgress,
                minHeight: 8,
                backgroundColor: AppColors.progressBarBgOf(context),
                valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(
      BuildContext context, CourseProvider cp, double hp) {
    if (cp.isLoading && cp.courseCount == 0) {
      return const Column(
        children: [
          CourseCardShimmer(),
          CourseCardShimmer(),
          CourseCardShimmer(),
        ],
      );
    }

    if (cp.hasError && cp.courseCount == 0) {
      return EmptyState.error(
        message: cp.errorMessage ?? 'Failed to load courses',
        onRetry: () => context.read<CourseProvider>().refresh(),
      );
    }

    if (cp.filteredCourses.isEmpty) {
      return EmptyState.noCourses(
        onRefresh: () => context.read<CourseProvider>().refresh(),
      );
    }

    if (_Responsive.isTablet(context)) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hp),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: cp.filteredCourses.map((course) {
            return CourseCard(
              course: course,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailsScreen(courseId: course.id),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      children: cp.filteredCourses.map((course) {
        return Padding(
          padding: EdgeInsets.fromLTRB(hp, 0, hp, 14),
          child: CourseCard(
            course: course,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourseDetailsScreen(courseId: course.id),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String number;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const Spacer(),
          Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textOf(context),
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.text2Of(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── COURSES TAB ───────────────────────────────────────────────────────────────
class _CoursesTab extends StatelessWidget {
  const _CoursesTab();

  @override
  Widget build(BuildContext context) {
    final hp = _Responsive.horizontalPadding(context);
    final isTablet = _Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      body: Consumer<CourseProvider>(
        builder: (context, cp, _) {
          return RefreshIndicator(
            onRefresh: () => cp.refresh(),
            color: AppColors.cyan,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _FloatingHeader(
                  title: '📚 My Courses',
                  subtitle: 'View all your enrolled courses',
                ),
                if (cp.isLoading && cp.courseCount == 0)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.cyan),
                    ),
                  )
                else if (isTablet)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.8,
                      children: cp.courses.map((c) => CourseCard(
                        course: c,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDetailsScreen(courseId: c.id),
                          ),
                        ),
                      )).toList(),
                    ),
                  )
                else
                  ...cp.courses.map(
                        (c) => Padding(
                      padding: EdgeInsets.fromLTRB(hp, 0, hp, 16),
                      child: CourseCard(
                        course: c,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDetailsScreen(courseId: c.id),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── PROGRESS TAB ──────────────────────────────────────────────────────────────
class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    final hp = _Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      body: Consumer<CourseProvider>(
        builder: (context, cp, _) {
          final pct = (cp.overallProgress * 100).toInt();
          return RefreshIndicator(
            onRefresh: () => cp.refresh(),
            color: AppColors.cyan,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _FloatingHeader(
                  title: '📈 My Progress',
                  subtitle: 'Track your learning journey',
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hp),
                  child: Row(
                    children: [
                      _ProgressStat(
                        icon: Icons.menu_book_rounded,
                        iconColor: AppColors.primary,
                        number: '${cp.courseCount}',
                        label: 'Total Courses',
                      ),
                      const SizedBox(width: 12),
                      _ProgressStat(
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.green,
                        number: '${cp.completedLecturesCount}',
                        label: 'Completed',
                      ),
                      const SizedBox(width: 12),
                      _ProgressStat(
                        icon: Icons.bar_chart_rounded,
                        iconColor: AppColors.cyan,
                        number: '$pct%',
                        label: 'Overall',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hp),
                  child: Text(
                    'Course-wise Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textOf(context),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...cp.courses.map((c) => _CourseProgressItem(course: c)),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String number;
  final String label;

  const _ProgressStat({
    required this.icon,
    required this.iconColor,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              number,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textOf(context),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.text2Of(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseProgressItem extends StatelessWidget {
  final Course course;

  const _CourseProgressItem({required this.course});

  @override
  Widget build(BuildContext context) {
    final hp = _Responsive.horizontalPadding(context);
    final pct = course.progress;

    return Container(
      margin: EdgeInsets.fromLTRB(hp, 0, hp, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOf(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: pct > 0 ? AppColors.cyan : AppColors.text2Of(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: course.progressDecimal,
              minHeight: 7,
              backgroundColor: AppColors.progressBarBgOf(context),
              valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${course.completedLectures}/${course.totalLectures} lectures completed',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.text2Of(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CERTIFICATES TAB ──────────────────────────────────────────────────────────
class _CertificatesTab extends StatefulWidget {
  const _CertificatesTab();

  @override
  State<_CertificatesTab> createState() => _CertificatesTabState();
}

class _CertificatesTabState extends State<_CertificatesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CertificateProvider>().fetchCertificates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hp = _Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      body: Consumer<CertificateProvider>(
        builder: (context, cp, _) {
          return RefreshIndicator(
            onRefresh: () => cp.refresh(),
            color: AppColors.cyan,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _FloatingHeader(
                    title: '🏆 Certificates',
                    subtitle: 'Your earned certificates',
                  ),
                ),
                if (cp.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.cyan),
                    ),
                  )
                else if (cp.hasError)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        cp.errorMessage ?? 'Failed to load',
                        style: TextStyle(color: AppColors.text2Of(context)),
                      ),
                    ),
                  )
                else if (cp.certificates.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(context),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) => _CertificateCard(
                          cert: cp.certificates[i],
                          hp: hp,
                        ),
                        childCount: cp.certificates.length,
                      ),
                    ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cyanLight, Color(0xFFd0f5f4)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text('🎖️', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No certificates yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pass your exams to earn certificates!',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text2Of(context),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Certificate Card ──────────────────────────────────────────────────────────
class _CertificateCard extends StatelessWidget {
  final Certificate cert;
  final double hp;

  const _CertificateCard({required this.cert, required this.hp});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.fromLTRB(hp, 0, hp, 16),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_rounded,
                      color: Color(0xFFFFBF00),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'CERTIFICATE OF COMPLETION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course name
                Text(
                  cert.courseName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textOf(context),
                  ),
                ),

                // College name
                if (cert.collegeName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.business_rounded,
                        size: 12,
                        color: AppColors.text2Of(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cert.collegeName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text2Of(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Issued On
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Issued On',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text2Of(context),
                      ),
                    ),
                    Text(
                      cert.formattedDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOf(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Certificate No
                Text(
                  'Certificate No',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.text2Of(context),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cert.certificateNumber,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOf(context),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // View & Download button — cyan gradient (login button sarkha)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CertificateViewScreen(cert: cert),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.cyan, AppColors.cyanDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, color: Colors.white, size: 17),
                        SizedBox(width: 8),
                        Text(
                          'View & Download',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}

// ── Floating Header ───────────────────────────────────────────────────────────
class _FloatingHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FloatingHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final hp = _Responsive.horizontalPadding(context);

    return Container(
      color: AppColors.bgOf(context),
      padding: EdgeInsets.fromLTRB(hp, topPadding + 14, hp, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}