/// Course Details Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/api_config.dart';
import '../../utils/app_colors.dart';
import '../../models/lecture.dart';
import '../../providers/course_provider.dart';
import '../../providers/lecture_provider.dart';
import '../../widgets/empty_state.dart';
import '../lecture/video_player_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LectureProvider>().fetchLectures(courseId: widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final course = context.read<CourseProvider>().getCourseById(widget.courseId);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            // ── Dark Header ──
            _buildHeader(context, course),

            // ── Scrollable Content ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Course Info Card
                  _buildCourseInfoCard(course),
                  const SizedBox(height: 16),

                  // Lectures Card
                  _buildLecturesCard(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context, course) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row — back + logo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const Spacer(),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Course',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: 'Mart',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 36), // balance
                ],
              ),
            ),

            // Course card inside header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: course != null && course.thumbnail.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: ApiConfig.buildMediaUrl(course.thumbnail),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white54,
                            size: 28,
                          ),
                        ),
                      )
                          : const Icon(Icons.menu_book_rounded,
                          color: Colors.white54, size: 28),
                    ),
                    const SizedBox(width: 14),

                    // Title + description + chips
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course?.title ?? 'Course Details',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (course?.description.isNotEmpty ?? false) ...[
                            const SizedBox(height: 2),
                            Text(
                              course!.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Chips
                          Row(
                            children: [
                              _buildChip(
                                Icons.access_time_rounded,
                                '${course?.duration ?? 0} Hours',
                              ),
                              const SizedBox(width: 6),
                              _buildChip(
                                Icons.check_circle_outline_rounded,
                                '${course?.completedLectures ?? 0}/${course?.totalLectures ?? 0}',
                              ),
                              const SizedBox(width: 6),
                              _buildChip(
                                Icons.bar_chart_rounded,
                                '${course?.progress ?? 0}%',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.cyan),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Course Info Card ──
  Widget _buildCourseInfoCard(course) {
    if (course == null) return const SizedBox.shrink();

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEF0F5)),
          const SizedBox(height: 12),

          _buildInfoRow('Duration', '${course.duration} Hours'),
          const SizedBox(height: 10),
          _buildInfoRow('Lectures', '${course.totalLectures}'),
          const SizedBox(height: 10),
          _buildInfoRow('Progress', '${course.progress}%'),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: course.progressDecimal,
              minHeight: 8,
              backgroundColor: AppColors.progressBarBg,
              valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${course.completedLectures} of ${course.totalLectures} lectures completed',
            style: const TextStyle(fontSize: 11, color: AppColors.text2),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: AppColors.text2)),
        Text(value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            )),
      ],
    );
  }

  // ── Lectures Card ──
  Widget _buildLecturesCard(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lectures',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEF0F5)),
          const SizedBox(height: 8),

          Consumer<LectureProvider>(
            builder: (context, lp, _) {
              if (lp.isLoading && lp.lectureCount == 0) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  ),
                );
              }

              if (lp.hasError && lp.lectureCount == 0) {
                return EmptyState.error(
                  message: lp.errorMessage ?? 'Failed to load lectures',
                  onRetry: () => context.read<LectureProvider>().refresh(),
                );
              }

              if (lp.lectures.isEmpty) {
                return EmptyState.noLectures();
              }

              return Column(
                children: lp.lectures.map((lecture) {
                  return _buildLectureTile(context, lecture);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Lecture Tile ──
  Widget _buildLectureTile(BuildContext context, Lecture lecture) {
    final isReady = lecture.isReady;

    return GestureDetector(
      onTap: isReady
          ? () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(lectureId: lecture.id),
        ),
      )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Number
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${lecture.lectureNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.topic,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status + arrow
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lecture.isFailed) ...[
                  const Icon(Icons.cancel_outlined,
                      size: 14, color: Color(0xFFE53935)),
                  const SizedBox(width: 4),
                  const Text('Failed',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE53935))),
                ] else if (isReady) ...[
                  const Icon(Icons.play_circle_outline_rounded,
                      size: 14, color: AppColors.cyan),
                  const SizedBox(width: 4),
                  const Text('Watch',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cyan)),
                ] else ...[
                  const Icon(Icons.hourglass_empty_rounded,
                      size: 14, color: AppColors.text2),
                  const SizedBox(width: 4),
                  Text(
                    lecture.isProcessing ? 'Processing' : 'Uploading',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.text2),
                  ),
                ],
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.text2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}