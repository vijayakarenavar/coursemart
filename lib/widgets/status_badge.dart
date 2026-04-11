/// Status Badge Widget
///
/// Reusable badge component displaying video status
/// with color-coded indicators.
library;

import 'package:flutter/material.dart';

import '../models/lecture.dart';

/// Status Badge Widget
///
/// Displays video status with color-coded badge:
/// - Ready: Green
/// - Processing: Orange
/// - Failed: Red
/// - Uploading: Blue
/// - Unknown: Grey
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status icon
          Icon(_getIcon(), size: fontSize + 2, color: Colors.white),
          const SizedBox(width: 4),
          // Status text
          Text(
            _getLabel(),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Get background color based on status
  Color _getBackgroundColor() {
    switch (status) {
      case VideoStatus.ready:
        return const Color(0xFF4CAF50); // Green
      case VideoStatus.processing:
        return const Color(0xFFFF9800); // Orange
      case VideoStatus.failed:
        return const Color(0xFFF44336); // Red
      case VideoStatus.uploading:
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get icon based on status
  IconData _getIcon() {
    switch (status) {
      case VideoStatus.ready:
        return Icons.check_circle;
      case VideoStatus.processing:
        return Icons.hourglass_top;
      case VideoStatus.failed:
        return Icons.error;
      case VideoStatus.uploading:
        return Icons.cloud_upload;
      default:
        return Icons.help_outline;
    }
  }

  /// Get display label based on status
  String _getLabel() {
    switch (status) {
      case VideoStatus.ready:
        return 'Ready';
      case VideoStatus.processing:
        return 'Processing';
      case VideoStatus.failed:
        return 'Failed';
      case VideoStatus.uploading:
        return 'Uploading';
      default:
        return 'Unknown';
    }
  }
}

/// Compact status badge (icon only, no text)
class CompactStatusBadge extends StatelessWidget {
  final String status;
  final double size;

  const CompactStatusBadge({super.key, required this.status, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        shape: BoxShape.circle,
      ),
      child: Icon(_getIcon(), size: size * 0.6, color: Colors.white),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case VideoStatus.ready:
        return const Color(0xFF4CAF50);
      case VideoStatus.processing:
        return const Color(0xFFFF9800);
      case VideoStatus.failed:
        return const Color(0xFFF44336);
      case VideoStatus.uploading:
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getIcon() {
    switch (status) {
      case VideoStatus.ready:
        return Icons.check;
      case VideoStatus.processing:
        return Icons.hourglass_top;
      case VideoStatus.failed:
        return Icons.close;
      case VideoStatus.uploading:
        return Icons.cloud_upload;
      default:
        return Icons.help;
    }
  }
}
