/// Lecture Tile Widget
///
/// Reusable list tile for displaying lecture information
/// with lecture number, topic, trainer, and video status badge.
library;

import 'package:flutter/material.dart';

import '../models/lecture.dart';
import 'status_badge.dart';

/// Lecture Tile Widget
///
/// Displays lecture information in a list tile format with:
/// - Lecture number (leading)
/// - Topic and trainer name
/// - Upload date
/// - Video status badge
///
/// Tappable to navigate to video player (only if video is ready)
class LectureTile extends StatelessWidget {
  final Lecture lecture;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPressed;

  const LectureTile({
    super.key,
    required this.lecture,
    this.onTap,
    this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: lecture.isReady ? (onTap ?? onPlayPressed) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Lecture number
              _buildLectureNumber(context),

              const SizedBox(width: 12),

              // Lecture info
              Expanded(child: _buildLectureInfo()),

              // Status badge and play button
              _buildTrailing(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build lecture number circle
  Widget _buildLectureNumber(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${lecture.lectureNumber}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  /// Build lecture info (topic, trainer, date)
  Widget _buildLectureInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic
        Text(
          lecture.topic,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Trainer name
        Row(
          children: [
            Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                lecture.trainerName,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),

        // Upload date
        Row(
          children: [
            Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              lecture.formattedUploadDate,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  /// Build trailing section (status badge + play button)
  Widget _buildTrailing(BuildContext context) {
    return Column(
      children: [
        // Status badge
        StatusBadge(status: lecture.videoStatus),

        const SizedBox(height: 8),

        // Play button (only if ready)
        if (lecture.isReady)
          IconButton(
            onPressed: onPlayPressed ?? onTap,
            icon: Icon(
              Icons.play_circle_filled,
              size: 28,
              color: Theme.of(context).primaryColor,
            ),
            tooltip: 'Play Lecture',
          )
        else
          // Status message for non-ready videos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _getStatusMessage(),
              style: TextStyle(
                fontSize: 10,
                color: _getStatusMessageColor(),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// Get status message for non-ready videos
  String _getStatusMessage() {
    switch (lecture.videoStatus) {
      case VideoStatus.processing:
        return 'Processing...';
      case VideoStatus.failed:
        return 'Failed';
      case VideoStatus.uploading:
        return 'Uploading...';
      default:
        return 'Not Available';
    }
  }

  /// Get status message color
  Color _getStatusMessageColor() {
    switch (lecture.videoStatus) {
      case VideoStatus.processing:
        return Colors.orange;
      case VideoStatus.failed:
        return Colors.red;
      case VideoStatus.uploading:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
