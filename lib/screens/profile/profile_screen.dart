/// Profile Screen - CourseMart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (_, auth, __) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.cyan,
                child: Text(
                  auth.studentName.isNotEmpty
                      ? auth.studentName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatarHeader(context),
            const SizedBox(height: 20),
            _sectionLabel('Account Info'),
            _buildInfoCard(context),
            const SizedBox(height: 20),
            _sectionLabel('Actions'),
            _buildActionButtons(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Dark navy header with avatar
  Widget _buildAvatarHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            bottomLeft:  Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            // Avatar circle with cyan gradient
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.cyan, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.cyan.withOpacity(0.4),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  auth.studentName.isNotEmpty
                      ? auth.studentName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              auth.studentName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              auth.studentEmail,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 10),
            // Student badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.15),
                border: Border.all(
                  color: AppColors.cyan.withOpacity(0.4),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Student',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section label like "Account Info", "Actions"
  Widget _sectionLabel(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.text2,
        letterSpacing: 0.8,
      ),
    ),
  );

  /// White card with info rows
  Widget _buildInfoCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final student = auth.student;
        if (student == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _infoRow(
                icon: Icons.badge_outlined,
                iconBg: const Color(0xFFE6F1FB),
                iconColor: const Color(0xFF378ADD),
                label: 'Roll Number',
                value: student.rollNumber,
              ),
              _divider(),
              _infoRow(
                icon: Icons.email_outlined,
                iconBg: AppColors.cyanLight,
                iconColor: AppColors.cyanDark,
                label: 'Email',
                value: student.email,
              ),
              _divider(),
              _infoRow(
                icon: Icons.school_outlined,
                iconBg: const Color(0xFFEAF3DE),
                iconColor: AppColors.green,
                label: 'College',
                value: student.collegeName,
              ),
              _divider(),
              _infoRow(
                icon: Icons.menu_book_outlined,
                iconBg: const Color(0xFFFBEAF0),
                iconColor: AppColors.pink,
                label: 'Enrolled Courses',
                value: '${student.enrolledCourses.length} Courses',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                        fontSize: 10, color: AppColors.text2,
                      )),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      )),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _divider() => const Divider(
    height: 1, thickness: 0.5,
    color: Color(0xFFE8F0F8),
    indent: 62,
    endIndent: 14,
  );

  /// Change Password + Logout buttons
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Change Password
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
              },
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Change Password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.cyan, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Logout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
              await context.read<AuthProvider>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}