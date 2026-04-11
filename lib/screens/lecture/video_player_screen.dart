/// Video Player Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/lecture.dart';
import '../../providers/lecture_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/error_handler.dart';
import '../../utils/download_manager.dart';
import '../../widgets/empty_state.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String lectureId;
  const VideoPlayerScreen({super.key, required this.lectureId});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  Lecture? _lecture;
  bool _isLoading = true;
  bool _isDownloadingNotes = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadLectureDetails();
  }

  Future<void> _loadLectureDetails() async {
    setState(() => _isLoading = true);
    try {
      final lecture = await context.read<LectureProvider>().getLectureDetails(widget.lectureId);
      if (!mounted) return;
      setState(() {
        _lecture = lecture;
        _isLoading = false;
        if (lecture.hasVideo) {
          _controller = YoutubePlayerController(
            initialVideoId: lecture.youtubeVideoId!,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              enableCaption: true,
              hideControls: false,
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, getErrorMessage(e));
    }
  }

  Future<void> _downloadNotes() async {
    if (_lecture?.notesUrl == null || _lecture!.notesUrl!.isEmpty) {
      showInfoSnackBar(context, 'Notes not available for this lecture');
      return;
    }
    setState(() { _isDownloadingNotes = true; _downloadProgress = 0.0; });
    try {
      final fileName = 'notes_lecture_${_lecture!.lectureNumber}.pdf';
      await DownloadManager().downloadAndOpen(
        url: _lecture!.notesUrl!,
        fileName: fileName,
        onProgress: (received, total) {
          if (mounted) setState(() => _downloadProgress = received / total);
        },
      );
      if (mounted) showSuccessSnackBar(context, 'Notes opened successfully!');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to download notes: ${getErrorMessage(e)}');
    } finally {
      if (mounted) setState(() { _isDownloadingNotes = false; _downloadProgress = 0.0; });
    }
  }

  void _goToLecture(Lecture lecture) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(lectureId: lecture.id),
      ),
    );
  }

  @override
  void dispose() {
    if (_controller?.value.isReady ?? false) _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
            : _lecture == null
            ? EmptyState.noLectures()
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final lectures = context.read<LectureProvider>().lectures;
    final currentIndex = lectures.indexWhere((l) => l.id == widget.lectureId);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < lectures.length - 1;

    return Column(
      children: [
        // ── Top Bar ──
        _buildTopBar(),

        // ── Scrollable Content ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Video section
                _buildVideoSection(),
                const SizedBox(height: 16),

                // Lecture Details card
                _buildDetailsCard(),
                const SizedBox(height: 16),

                // Lecture Notes card
                if (_lecture!.hasNotes) ...[
                  _buildNotesCard(),
                  const SizedBox(height: 16),
                ],

                // All Lectures card
                _buildAllLecturesCard(lectures, currentIndex),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Bottom Nav ──
        _buildBottomNav(lectures, currentIndex, hasPrev, hasNext),
      ],
    );
  }

  // ── Top Bar ──
  Widget _buildTopBar() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _lecture?.topic ?? 'Lecture',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Lecture Video',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Video Section ──
  Widget _buildVideoSection() {
    // Failed
    if (_lecture!.isFailed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: AppColors.red),
            SizedBox(height: 8),
            Text(
              'Video upload failed',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Please contact admin for assistance.',
              style: TextStyle(fontSize: 12, color: AppColors.text2),
            ),
          ],
        ),
      );
    }

    // Has YouTube video
    if (_lecture!.hasVideo && _controller != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.cyan,
        ),
      );
    }

    // Ready but no video ID — Watch button
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            'Click below to watch this lecture',
            style: TextStyle(
                fontSize: 13, color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Watch Lecture',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lecture Details Card ──
  Widget _buildDetailsCard() {
    return _buildCard(
      title: 'Lecture Details',
      child: Column(
        children: [
          _buildDetailRow(Icons.menu_book_rounded, 'Topic', _lecture!.topic),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.person_outline_rounded, 'Trainer', _lecture!.trainerName),
          const SizedBox(height: 10),
          _buildDetailRow(Icons.calendar_today_rounded, 'Upload Date',
              _lecture!.formattedUploadDate),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.text2),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.text2)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
      ],
    );
  }

  // ── Notes Card ──
  Widget _buildNotesCard() {
    return _buildCard(
      title: 'Lecture Notes',
      child: GestureDetector(
        onTap: _isDownloadingNotes ? null : _downloadNotes,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.red, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Download Lecture Notes',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                    Text('PDF Document',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.text2)),
                  ],
                ),
              ),
              _isDownloadingNotes
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _downloadProgress,
                  color: AppColors.red,
                ),
              )
                  : const Icon(Icons.open_in_new_rounded,
                  size: 18, color: AppColors.text2),
            ],
          ),
        ),
      ),
    );
  }

  // ── All Lectures Card ──
  Widget _buildAllLecturesCard(List<Lecture> lectures, int currentIndex) {
    return _buildCard(
      title: 'All Lectures',
      child: Column(
        children: lectures.asMap().entries.map((entry) {
          final index = entry.key;
          final lecture = entry.value;
          final isCurrent = index == currentIndex;
          final isReady = lecture.isReady;

          return GestureDetector(
            onTap: isCurrent ? null : () => _goToLecture(lecture),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.cyanLight
                    : AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '${lecture.lectureNumber}.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? AppColors.cyan : AppColors.text2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lecture.topic,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCurrent ? AppColors.cyan : AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: lecture.isFailed
                          ? AppColors.red.withOpacity(0.15)
                          : isReady
                          ? AppColors.cyan.withOpacity(0.15)
                          : AppColors.text2.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      lecture.isFailed
                          ? Icons.cancel_rounded
                          : isReady
                          ? Icons.play_arrow_rounded
                          : Icons.hourglass_empty_rounded,
                      size: 16,
                      color: lecture.isFailed
                          ? AppColors.red
                          : isReady
                          ? AppColors.cyan
                          : AppColors.text2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Bottom Nav ──
  Widget _buildBottomNav(
      List<Lecture> lectures, int currentIndex, bool hasPrev, bool hasNext) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous
          Expanded(
            child: GestureDetector(
              onTap: hasPrev ? () => _goToLecture(lectures[currentIndex - 1]) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: hasPrev ? AppColors.bg : AppColors.bg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasPrev
                        ? AppColors.text2.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_left_rounded,
                        size: 18,
                        color: hasPrev ? AppColors.text : AppColors.text2),
                    Text(
                      'Previous Lecture',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasPrev ? AppColors.text : AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Next
          Expanded(
            child: GestureDetector(
              onTap: hasNext ? () => _goToLecture(lectures[currentIndex + 1]) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: hasNext ? AppColors.primary : AppColors.text2.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next Lecture',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasNext ? Colors.white : AppColors.text2,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18,
                        color: hasNext ? Colors.white : AppColors.text2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Card ──
  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
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
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              )),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEF0F5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}