/// Course Details Screen
/// ✅ Dark Mode | ✅ Responsive | ✅ Safe Area | ✅ Landscape
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: AppColors.bgOf(context),
        body: isLandscape
            ? _buildLandscape(context, course)
            : _buildPortrait(context, course),
      ),
    );
  }

  Widget _buildPortrait(BuildContext context, course) {
    return Column(
      children: [
        _buildHeader(context, course),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCourseInfoCard(context, course),
              const SizedBox(height: 16),
              _buildLecturesCard(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscape(BuildContext context, course) {
    return Column(
      children: [
        _buildHeader(context, course),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCourseInfoCard(context, course),
              const SizedBox(height: 16),
              _buildLecturesCard(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, course) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
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
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const Spacer(),
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                          text: 'Course',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      TextSpan(
                          text: 'Mart',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.cyan)),
                    ]),
                  ),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14)),
                      child: course != null && course.thumbnail.isNotEmpty
                          ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                              imageUrl: ApiConfig.buildMediaUrl(
                                  course.thumbnail),
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.white54,
                                  size: 28)))
                          : const Icon(Icons.menu_book_rounded,
                          color: Colors.white54, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(course?.title ?? 'Course Details',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (course?.description.isNotEmpty ?? false) ...[
                            const SizedBox(height: 2),
                            Text(course?.description ?? '',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // ✅ 0 Hours लपवलं
                              if ((course?.duration ?? 0) > 0) ...[
                                _buildChip(Icons.access_time_rounded,
                                    '${course!.duration} hrs'),
                                const SizedBox(width: 6),
                              ],
                              _buildChip(Icons.check_circle_outline_rounded,
                                  '${course?.completedLectures ?? 0}/${course?.totalLectures ?? 0}'),
                              const SizedBox(width: 6),
                              _buildChip(Icons.bar_chart_rounded,
                                  '${course?.progress ?? 0}%'),
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

  Widget _buildChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.cyan),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white)),
    ]),
  );

  Widget _buildCourseInfoCard(BuildContext context, course) {
    if (course == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Course Info',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textOf(context))),
          const SizedBox(height: 12),
          Divider(
              height: 1,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFEEF0F5)),
          const SizedBox(height: 12),
          // ✅ 0 Hours लपवलं
          if (course.duration > 0) ...[
            _buildInfoRow(context, 'Duration', '${course.duration} Hours'),
            const SizedBox(height: 10),
          ],
          _buildInfoRow(context, 'Lectures', '${course.totalLectures}'),
          const SizedBox(height: 10),
          _buildInfoRow(context, 'Progress', '${course.progress}%'),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
                value: course.progressDecimal,
                minHeight: 8,
                backgroundColor: AppColors.progressBarBgOf(context),
                valueColor:
                const AlwaysStoppedAnimation(AppColors.cyan)),
          ),
          const SizedBox(height: 8),
          Text(
              '${course.completedLectures} of ${course.totalLectures} lectures completed',
              style: TextStyle(
                  fontSize: 11, color: AppColors.text2Of(context))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14, color: AppColors.text2Of(context))),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textOf(context))),
        ],
      );

  Widget _buildLecturesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lectures',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textOf(context))),
          const SizedBox(height: 12),
          Divider(
              height: 1,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFEEF0F5)),
          const SizedBox(height: 8),
          Consumer<LectureProvider>(
            builder: (context, lp, _) {
              if (lp.isLoading && lp.lectureCount == 0) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            color: AppColors.cyan)));
              }
              if (lp.hasError && lp.lectureCount == 0) {
                return EmptyState.error(
                    message:
                    lp.errorMessage ?? 'Failed to load lectures',
                    onRetry: () =>
                        context.read<LectureProvider>().refresh());
              }
              if (lp.lectures.isEmpty) return EmptyState.noLectures();
              // ✅ Serial number 1,2,3...
              return Column(
                children: lp.lectures
                    .asMap()
                    .entries
                    .map((entry) => _buildLectureTile(
                    context, entry.value, entry.key + 1))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ serialNo parameter
  // ✅ serialNo parameter
  Widget _buildLectureTile(
      BuildContext context, Lecture lecture, int serialNo) {
    final isReady = lecture.isReady;

    return GestureDetector(
      // ✅ आता कोणत्याही स्टेटसवर (Processing/Uploading/Failed/Ready) क्लिक केल्यावर व्हिडिओ पेजवर जाईल
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  VideoPlayerScreen(lectureId: lecture.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.bgOf(context),
            borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: Center(
                child: Text('$serialNo',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(lecture.topic,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOf(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (lecture.isFailed) ...[
                const Icon(Icons.cancel_outlined,
                    size: 14, color: AppColors.red),
                const SizedBox(width: 4),
                const Text('Failed',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red))
              ] else if (isReady) ...[
                const Icon(Icons.play_circle_outline_rounded,
                    size: 14, color: AppColors.cyan),
                const SizedBox(width: 4),
                const Text('Watch',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan))
              ] else ...[
                const Icon(Icons.hourglass_empty_rounded,
                    size: 14, color: AppColors.text2),
                const SizedBox(width: 4),
                Text(
                    lecture.isProcessing ? 'Processing' : 'Uploading',
                    style: const TextStyle(fontSize: 12, color: AppColors.text2))
              ],
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.text2Of(context)),
            ]),
          ],
        ),
      ),
    );
  }
}