/// Video Player Screen
/// ✅ Dark Mode | ✅ Responsive | ✅ Safe Area | ✅ Landscape | ✅ Fullscreen
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
import 'PdfViewerScreen.dart';


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
  bool _hasError = false; // ✅ Error state track करायला
  bool _isDownloadingNotes = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadLectureDetails();
  }

  Future<void> _loadLectureDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false; // ✅ retry करताना error clear करा
    });
    try {
      final lecture = await context.read<LectureProvider>().getLectureDetails(widget.lectureId);
      if (!mounted) return;
      debugPrint('=== LECTURE DEBUG ===');
      debugPrint('ID: ${lecture.id}');
      debugPrint('Topic: ${lecture.topic}');
      debugPrint('hasVideo: ${lecture.hasVideo}');
      debugPrint('isFailed: ${lecture.isFailed}');
      debugPrint('youtubeVideoId: ${lecture.youtubeVideoId}');
      debugPrint('====================');
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
      // ✅ Error state set करा — snackbar नको, error UI दाखवा
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _downloadNotes() async {
    if (_lecture?.notesUrl == null || _lecture!.notesUrl!.isEmpty) {
      showInfoSnackBar(context, 'Notes not available for this lecture');
      return;
    }

    final fileName = 'notes_lecture_${_lecture!.lectureNumber}.pdf';

    final existingPath = await DownloadManager().getExistingFilePath(fileName);
    if (existingPath != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            filePath: existingPath,
            title: 'Lecture ${_lecture!.lectureNumber} Notes',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isDownloadingNotes = true;
      _downloadProgress = 0.0;
    });

    try {
      final filePath = await DownloadManager().downloadFile(
        url: _lecture!.notesUrl!,
        fileName: fileName,
        onProgress: (received, total) {
          if (mounted) setState(() => _downloadProgress = received / total);
        },
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            filePath: filePath,
            title: 'Lecture ${_lecture!.lectureNumber} Notes',
          ),
        ),
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to download notes: ${getErrorMessage(e)}');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingNotes = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  void _goToNextLecture(Lecture lecture) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => VideoPlayerScreen(lectureId: lecture.id),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _goToPrevLecture(Lecture lecture) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => VideoPlayerScreen(lectureId: lecture.id),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.cardOf(context),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    if (_controller == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          backgroundColor: AppColors.bgOf(context),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
              : _hasError
              ? _buildErrorState(context) // ✅ Error state
              : _lecture == null
              ? EmptyState.noLectures()
              : _buildContent(context, const SizedBox.shrink()),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.cyan,
      ),
      builder: (ctx, player) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Scaffold(
            backgroundColor: AppColors.bgOf(context),
            body: _buildContent(ctx, player),
          ),
        );
      },
    );
  }

  // ✅ Error state widget — net off/on scenario साठी
  Widget _buildErrorState(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.text2),
                const SizedBox(height: 16),
                Text(
                  'Could not load lecture',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check your internet and try again',
                  style: TextStyle(fontSize: 13, color: AppColors.text2Of(context)),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _loadLectureDetails,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.cyan, AppColors.cyanDark]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Try Again',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, Widget player) {
    final lectures = context.read<LectureProvider>().lectures;
    final currentIndex = lectures.indexWhere((l) => l.id == widget.lectureId);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < lectures.length - 1;

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        if (isLandscape && _lecture!.hasVideo && _controller != null) {
          return Container(
            color: Colors.black,
            child: Center(child: player),
          );
        }

        return Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildVideoSection(context, player),
                    const SizedBox(height: 16),
                    _buildDetailsCard(context),
                    const SizedBox(height: 16),
                    if (_lecture!.hasNotes) ...[
                      _buildNotesCard(context),
                      const SizedBox(height: 16),
                    ],
                    _buildAllLecturesCard(context, lectures, currentIndex),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomNav(context, lectures, currentIndex, hasPrev, hasNext),
          ],
        );
      },
    );
  }

  Widget _buildVideoSection(BuildContext context, Widget player) {
    if (_lecture!.isFailed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(children: [
          Icon(Icons.error_outline_rounded, size: 40, color: AppColors.red),
          SizedBox(height: 8),
          Text('Video upload failed',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.red)),
          SizedBox(height: 4),
          Text('Please contact admin for assistance.',
              style: TextStyle(fontSize: 12, color: AppColors.text2)),
        ]),
      );
    }

    if (_lecture!.hasVideo && _controller != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: player,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            'Click below to watch this lecture',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Watch Lecture', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _lecture?.topic ?? 'Lecture',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
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
                child: const Text('Lecture Video',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return _buildCard(context,
        title: 'Lecture Details',
        child: Column(children: [
          _buildDetailRow(context, Icons.menu_book_rounded, 'Topic', _lecture!.topic),
          const SizedBox(height: 10),
          _buildDetailRow(context, Icons.person_outline_rounded, 'Trainer', _lecture!.trainerName),
          const SizedBox(height: 10),
          _buildDetailRow(context, Icons.calendar_today_rounded, 'Upload Date',
              _lecture!.formattedUploadDate),
        ]));
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.text2Of(context)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.text2Of(context))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textOf(context),
              ),
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _buildNotesCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildCard(
        context,
        title: 'Lecture Notes',
        child: GestureDetector(
          onTap: _isDownloadingNotes ? null : _downloadNotes,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.red.withOpacity(0.12) : const Color(0xFFFFF3F0),
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
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('View Lecture Notes',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textOf(context))),
                    Text('PDF Document',
                        style: TextStyle(fontSize: 11, color: AppColors.text2Of(context))),
                  ]),
                ),
                _isDownloadingNotes
                    ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                        color: AppColors.red))
                    : Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: AppColors.text2Of(context)),
              ],
            ),
          ),
        ));
  }

  Widget _buildAllLecturesCard(BuildContext context, List<Lecture> lectures, int currentIndex) {
    return _buildCard(
        context,
        title: 'All Lectures',
        child: Column(
          children: lectures.asMap().entries.map((entry) {
            final index = entry.key;
            final lecture = entry.value;
            final isCurrent = index == currentIndex;
            final isReady = lecture.isReady;

            return GestureDetector(
              onTap: isCurrent
                  ? null
                  : () {
                if (index > currentIndex) {
                  _goToNextLecture(lecture);
                } else {
                  _goToPrevLecture(lecture);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.cyanLight : AppColors.bgOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('${lecture.lectureNumber}.',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? AppColors.cyan : AppColors.text2Of(context))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(lecture.topic,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCurrent ? AppColors.cyan : AppColors.textOf(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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
                            : AppColors.text2Of(context).withOpacity(0.1),
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
                            : AppColors.text2Of(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ));
  }

  Widget _buildBottomNav(BuildContext context, List<Lecture> lectures, int currentIndex,
      bool hasPrev, bool hasNext) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -4))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: hasPrev ? () => _goToPrevLecture(lectures[currentIndex - 1]) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: hasPrev
                        ? AppColors.bgOf(context)
                        : AppColors.bgOf(context).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: hasPrev
                            ? AppColors.text2Of(context).withOpacity(0.3)
                            : Colors.transparent),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.chevron_left_rounded,
                        size: 18,
                        color: hasPrev ? AppColors.textOf(context) : AppColors.text2Of(context)),
                    Text('Previous',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: hasPrev
                                ? AppColors.textOf(context)
                                : AppColors.text2Of(context))),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: hasNext ? () => _goToNextLecture(lectures[currentIndex + 1]) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: hasNext
                        ? AppColors.primary
                        : AppColors.text2Of(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Next',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: hasNext ? Colors.white : AppColors.text2Of(context))),
                    Icon(Icons.chevron_right_rounded,
                        size: 18,
                        color: hasNext ? Colors.white : AppColors.text2Of(context)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
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
          Text(title,
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
          child,
        ],
      ),
    );
  }
}