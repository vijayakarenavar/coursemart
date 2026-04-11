/// Date formatting utilities
///
/// Helper functions for formatting dates and times
/// throughout the application.
library;

import 'package:intl/intl.dart';

/// Date formatting helper
///
/// Provides various date formatting utilities
class DateHelper {
  /// Format DateTime to readable string (e.g., "Mar 25, 2026")
  ///
  /// [date] - DateTime to format
  /// Returns formatted date string
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format DateTime to short string (e.g., "Mar 25")
  ///
  /// [date] - DateTime to format
  /// Returns short date string
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  /// Format DateTime to time string (e.g., "10:30 AM")
  ///
  /// [date] - DateTime to format
  /// Returns time string
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Format DateTime to date and time string (e.g., "Mar 25, 2026 10:30 AM")
  ///
  /// [date] - DateTime to format
  /// Returns date and time string
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  /// Format DateTime to relative time (e.g., "2 days ago", "Just now")
  ///
  /// [date] - DateTime to format
  /// Returns relative time string
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Format DateTime to ISO 8601 string
  ///
  /// [date] - DateTime to format
  /// Returns ISO 8601 string
  static String toIsoString(DateTime date) {
    return date.toIso8601String();
  }

  /// Parse ISO 8601 string to DateTime
  ///
  /// [isoString] - ISO 8601 string to parse
  /// Returns DateTime
  static DateTime fromIsoString(String isoString) {
    return DateTime.parse(isoString);
  }

  /// Get time ago from now
  ///
  /// [timestamp] - Timestamp in milliseconds
  /// Returns relative time string
  static String timeAgo(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return formatRelative(date);
  }

  /// Format duration to readable string
  ///
  /// [duration] - Duration to format
  /// Returns formatted duration string (e.g., "2h 30m")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Check if date is today
  ///
  /// [date] - DateTime to check
  /// Returns true if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  ///
  /// [date] - DateTime to check
  /// Returns true if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}
