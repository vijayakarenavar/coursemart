/// Empty State Widget
///
/// Reusable widget for displaying empty/error states
/// with icon, message, and optional action button.
library;

import 'package:flutter/material.dart';

/// Empty State Widget
///
/// Displays an empty state with:
/// - Icon
/// - Title message
/// - Subtitle (optional)
/// - Action button (optional)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionPressed,
    this.iconColor,
    this.iconSize = 64,
  });

  /// Empty state for no courses
  factory EmptyState.noCourses({VoidCallback? onRefresh}) {
    return EmptyState(
      icon: Icons.school_outlined,
      title: 'No courses found',
      subtitle: 'You haven\'t enrolled in any courses yet.',
      actionLabel: onRefresh != null ? 'Refresh' : null,
      onActionPressed: onRefresh,
    );
  }

  /// Empty state for no lectures
  factory EmptyState.noLectures() {
    return EmptyState(
      icon: Icons.video_library_outlined,
      title: 'No lectures found',
      subtitle: 'There are no lectures available for this course.',
    );
  }

  /// Empty state for no internet
  factory EmptyState.noInternet({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'No internet connection',
      subtitle: 'Please check your network settings and try again.',
      actionLabel: onRetry != null ? 'Retry' : null,
      onActionPressed: onRetry,
    );
  }

  /// Empty state for errors
  factory EmptyState.error({required String message, VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Oops! Something went wrong',
      subtitle: message,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onActionPressed: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(icon, size: iconSize, color: iconColor ?? Colors.grey[400]),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  subtitle!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),

            // Action button
            if (actionLabel != null && onActionPressed != null)
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
