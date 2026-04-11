/// Dashboard Screen
///
/// Main screen displaying enrolled courses with filtering,
/// pull-to-refresh, and navigation to course details.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/filter_chip.dart';
import '../course/course_details_screen.dart';
import '../profile/profile_screen.dart';
import '../../models/course.dart';

/// Main shell with bottom navigation bar
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    _CoursesTab(),
    _ProgressTab(),
    _CertificatesTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor:
        _currentIndex == 0 ? AppColors.primary : AppColors.bg,
        statusBarIconBrightness:
        _currentIndex == 0 ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: AppColors.card,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: _screens[_currentIndex],
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Dashboard',
                active: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.menu_book_rounded,
                label: 'Courses',
                active: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Progress',
                active: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavItem(
                icon: Icons.workspace_premium_rounded,
                label: 'Certificates',
                active: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Nav Item ───────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              color: active ? AppColors.cyan : AppColors.text2,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.cyan : AppColors.text2,
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── Dark header with CourseMart logo ──
          _buildHeader(context),

          // ── Scrollable content ──
          Expanded(
            child: Consumer<CourseProvider>(
              builder: (context, courseProvider, _) {
                return RefreshIndicator(
                  onRefresh: () => courseProvider.refresh(),
                  color: AppColors.cyan,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Welcome card
                      _buildWelcomeCard(context),
                      const SizedBox(height: 20),

                      // Stat cards 2x2
                      _buildStatGrid(context, courseProvider),
                      const SizedBox(height: 20),

                      // Overall progress bar card
                      _buildProgressCard(context, courseProvider),
                      const SizedBox(height: 20),

                      // Filter tabs
                      // _buildFilterBar(context, courseProvider),
                      // const SizedBox(height: 16),

                      // Course list
                      _buildCourseList(context, courseProvider),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Row(
            children: [
              // CourseMart logo
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

              // Notification bell
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar — uses real student name initial
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

  // ── Welcome Card ──
  Widget _buildWelcomeCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Stack(
            children: [
              // Cyan glow top-right
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

  // ── Stat Grid 2x2 ──
  Widget _buildStatGrid(BuildContext context, CourseProvider courseProvider) {
    final enrolled = courseProvider.courseCount;
    final completed = courseProvider.completedLecturesCount;
    final remaining = courseProvider.remainingLecturesCount;
    final overallPct =
        '${(courseProvider.overallProgress * 100).toInt()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _StatCard(
            icon: Icons.menu_book_rounded,
            iconBg: AppColors.primary,
            number: '$enrolled',
            label: 'Enrolled Courses',
          ),
          _StatCard(
            icon: Icons.check_circle_rounded,
            iconBg: AppColors.green,
            number: '$completed',
            label: 'Completed Lectures',
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
            label: 'Overall Progress',
          ),
        ],
      ),
    );
  }

  // ── Overall Progress Card ──
  Widget _buildProgressCard(
      BuildContext context, CourseProvider courseProvider) {
    final pct = (courseProvider.overallProgress * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
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
                const Text(
                  'Overall Learning Progress',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
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
                value: courseProvider.overallProgress,
                minHeight: 8,
                backgroundColor: AppColors.progressBarBg,
                valueColor:
                const AlwaysStoppedAnimation(AppColors.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter Bar ──
  // Widget _buildFilterBar(
  //     BuildContext context, CourseProvider courseProvider) {
  //   return Consumer<CourseProvider>(
  //     builder: (context, cp, _) {
  //       return FilterBar(
  //         options: FilterBar.courseFilters,
  //         selectedValue: cp.filter,
  //         onFilterChanged: (filter) => cp.setFilter(filter),
  //       );
  //     },
  //   );
  // }

  // ── Course List ──
  Widget _buildCourseList(
      BuildContext context, CourseProvider courseProvider) {
    // Loading
    if (courseProvider.isLoading && courseProvider.courseCount == 0) {
      return Column(
        children: const [
          CourseCardShimmer(),
          CourseCardShimmer(),
          CourseCardShimmer(),
        ],
      );
    }

    // Error
    if (courseProvider.hasError && courseProvider.courseCount == 0) {
      return EmptyState.error(
        message:
        courseProvider.errorMessage ?? 'Failed to load courses',
        onRetry: () => context.read<CourseProvider>().refresh(),
      );
    }

    // Empty
    if (courseProvider.filteredCourses.isEmpty) {
      return EmptyState.noCourses(
        onRefresh: () => context.read<CourseProvider>().refresh(),
      );
    }

    // Courses
    return Column(
      children: courseProvider.filteredCourses.map((course) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: CourseCard(
            course: course,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CourseDetailsScreen(courseId: course.id),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const Spacer(),
          Text(
            number,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.text2),
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _FloatingHeader(
                title: '📚 My Courses',
                subtitle: 'View all your enrolled courses',
              ),
              if (courseProvider.isLoading && courseProvider.courseCount == 0)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                        color: AppColors.cyan),
                  ),
                )
              else
                ...courseProvider.courses.map(
                      (c) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: CourseCard(
                      course: c,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CourseDetailsScreen(courseId: c.id),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, _) {
          final pct =
          (courseProvider.overallProgress * 100).toInt();
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _FloatingHeader(
                title: '📈 My Progress',
                subtitle: 'Track your learning journey',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    _ProgressStat(
                      icon: Icons.menu_book_rounded,
                      iconColor: AppColors.primary,
                      number: '${courseProvider.courseCount}',
                      label: 'Total Courses',
                    ),
                    const SizedBox(width: 12),
                    _ProgressStat(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.green,
                      number:
                      '${courseProvider.completedLecturesCount}',
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Course-wise Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...courseProvider.courses
                  .map((c) => _CourseProgressItem(course: c)),
              const SizedBox(height: 20),
            ],
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
        padding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.text2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
class _CourseProgressItem extends StatelessWidget {
  final Course course; // dynamic ऐवजी Course type वापर

  const _CourseProgressItem({required this.course});

  @override
  Widget build(BuildContext context) {
    final pct = course.progress; // int 0-100, directly वापर

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
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
              Text(
                course.title, // ✅ title
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: pct > 0 ? AppColors.cyan : AppColors.text2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: course.progressDecimal, // ✅ 0.0-1.0
              minHeight: 7,
              backgroundColor: AppColors.progressBarBg,
              valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${course.completedLectures}/${course.totalLectures} lectures completed',
              style: const TextStyle(fontSize: 11, color: AppColors.text2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CERTIFICATES TAB ──────────────────────────────────────────────────────────
class _CertificatesTab extends StatelessWidget {
  const _CertificatesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _FloatingHeader(
            title: '🏆 Certificates',
            subtitle: 'Your earned certificates',
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        child: Text('🎖️',
                            style: TextStyle(fontSize: 48)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No certificates yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete your courses to earn certificates and showcase your skills!',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.text2,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Header (for non-dashboard tabs) ──────────────────────────────────
class _FloatingHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FloatingHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.fromLTRB(16, topPadding + 14, 16, 16),
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