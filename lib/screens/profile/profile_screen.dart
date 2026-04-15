/// Profile Screen
/// ✅ Dark Mode | ✅ Responsive | ✅ Safe Area | ✅ Landscape
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_dialogs.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<AuthProvider>(
            builder: (_, auth, _) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.cyan,
                child: Text(
                  auth.studentName.isNotEmpty ? auth.studentName[0].toUpperCase() : 'S',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLandscape
            ? _buildLandscape(context, isTablet)
            : _buildPortrait(context, isTablet),
      ),
    );
  }

  // ── Portrait ──────────────────────────────────────────────────────────────
  Widget _buildPortrait(BuildContext context, bool isTablet) {
    final hp = isTablet ? 24.0 : 14.0;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatarHeader(context),
          const SizedBox(height: 24),
          _sectionLabel(context, 'Account Info'),
          _buildInfoCard(context, hp),
          const SizedBox(height: 24),
          _sectionLabel(context, 'Actions'),
          _buildActionButtons(context, hp),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Landscape: avatar left, info right ───────────────────────────────────
  Widget _buildLandscape(BuildContext context, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: avatar header
        Expanded(
          flex: 4,
          child: SingleChildScrollView(child: _buildAvatarHeader(context)),
        ),
        // Right: info + actions
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(context, 'Account Info'),
                _buildInfoCard(context, 0),
                const SizedBox(height: 20),
                _sectionLabel(context, 'Actions'),
                _buildActionButtons(context, 0),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 36),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              width: 86, height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.cyan, AppColors.cyanDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Center(
                child: Text(
                  auth.studentName.isNotEmpty ? auth.studentName[0].toUpperCase() : 'S',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(auth.studentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2)),
            const SizedBox(height: 4),
            Text(auth.studentEmail, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
    child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2Of(context), letterSpacing: 0.9)),
  );

  Widget _buildInfoCard(BuildContext context, double hp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<AuthProvider>(
      builder: (_, auth, _) {
        final student = auth.student;
        if (student == null) return const SizedBox.shrink();
        return Container(
          margin: EdgeInsets.symmetric(horizontal: hp == 0 ? 0 : 14),
          decoration: BoxDecoration(
            color: AppColors.cardOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _infoRow(context, icon: Icons.badge_outlined, iconBg: const Color(0xFFE6F1FB), iconColor: const Color(0xFF378ADD), label: 'Roll Number', value: student.rollNumber),
              _divider(context),
              _infoRow(context, icon: Icons.email_outlined, iconBg: AppColors.cyanLight, iconColor: AppColors.cyanDark, label: 'Email', value: student.email),
              _divider(context),
              _infoRow(context, icon: Icons.school_outlined, iconBg: const Color(0xFFEAF3DE), iconColor: AppColors.green, label: 'College', value: student.collegeName),
              _divider(context),
              _infoRow(context, icon: Icons.menu_book_outlined, iconBg: const Color(0xFFFBEAF0), iconColor: AppColors.pink, label: 'Enrolled Courses', value: '${student.enrolledCourses.length} Courses'),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(BuildContext context, {required IconData icon, required Color iconBg, required Color iconColor, required String label, required String value}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: iconColor, size: 19)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: AppColors.text2Of(context), fontWeight: FontWeight.w500, letterSpacing: 0.3)),
              const SizedBox(height: 3),
              Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textOf(context))),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _divider(BuildContext context) => Divider(
    height: 1, thickness: 0.5,
    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.08) : const Color(0xFFECF2F8),
    indent: 68, endIndent: 16,
  );

  Widget _buildActionButtons(BuildContext context, double hp) => Padding(
    padding: EdgeInsets.symmetric(horizontal: hp == 0 ? 0 : 14),
    child: Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.cyan, AppColors.cyanDark]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 7))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => AppDialogs.showLogout(context, onConfirm: () async {
              AppDialogs.showLoading(context, message: 'Logging out...');
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                AppDialogs.hideLoading(context);
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            }),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15), elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    ),
  );
}