/// Lecture data model
///
/// Represents a lecture within a course with video
/// status and optional notes.
library;

/// Lecture model class
///
/// Contains all lecture-related data from the API
class Lecture {
  final String id;
  final int lectureNumber;
  final String topic;
  final String videoStatus; // ready, processing, failed, uploading
  final DateTime uploadedAt;
  final String trainerName;

  // Optional fields (available in lecture details endpoint)
  final String? youtubeVideoId;
  final String? notesUrl;
  final String? courseTitle;

  const Lecture({
    required this.id,
    required this.lectureNumber,
    required this.topic,
    required this.videoStatus,
    required this.uploadedAt,
    required this.trainerName,
    this.youtubeVideoId,
    this.notesUrl,
    this.courseTitle,
  });

  /// Create a Lecture from JSON map
  ///
  /// Handles null safety and provides default values
  factory Lecture.fromJson(Map<String, dynamic> json) {
    DateTime uploadedDate;
    if (json['uploadedAt'] != null) {
      if (json['uploadedAt'] is String) {
        uploadedDate = DateTime.tryParse(json['uploadedAt']) ?? DateTime.now();
      } else if (json['uploadedAt'] is DateTime) {
        uploadedDate = json['uploadedAt'];
      } else {
        uploadedDate = DateTime.now();
      }
    } else {
      uploadedDate = DateTime.now();
    }

    // parts array मधून youtubeVideoId काढा
    String? youtubeVideoId = json['youtubeVideoId'];
    if (youtubeVideoId == null) {
      final parts = json['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        final firstPart = parts[0] as Map<String, dynamic>?;
        youtubeVideoId = firstPart?['youtubeVideoId'] as String?;
      }
    }

    return Lecture(
      id: json['_id'] ?? json['id'] ?? '',
      lectureNumber: json['lectureNumber'] ?? 0,
      topic: json['topic'] ?? 'Untitled Lecture',
      videoStatus: json['videoStatus'] ?? VideoStatus.unknown,
      uploadedAt: uploadedDate,
      trainerName: json['trainerName'] ?? 'Unknown Trainer',
      youtubeVideoId: youtubeVideoId,
      notesUrl: json['notesUrl'],
      courseTitle: json['courseTitle'],
    );
  }

  /// Convert Lecture to JSON map
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'lectureNumber': lectureNumber,
      'topic': topic,
      'videoStatus': videoStatus,
      'uploadedAt': uploadedAt.toIso8601String(),
      'trainerName': trainerName,
      'youtubeVideoId': youtubeVideoId,
      'notesUrl': notesUrl,
      'courseTitle': courseTitle,
    };
  }

  /// Create a copy of Lecture with updated fields
  Lecture copyWith({
    String? id,
    int? lectureNumber,
    String? topic,
    String? videoStatus,
    DateTime? uploadedAt,
    String? trainerName,
    String? youtubeVideoId,
    String? notesUrl,
    String? courseTitle,
  }) {
    return Lecture(
      id: id ?? this.id,
      lectureNumber: lectureNumber ?? this.lectureNumber,
      topic: topic ?? this.topic,
      videoStatus: videoStatus ?? this.videoStatus,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      trainerName: trainerName ?? this.trainerName,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      notesUrl: notesUrl ?? this.notesUrl,
      courseTitle: courseTitle ?? this.courseTitle,
    );
  }

  /// Check if video is ready to watch
  bool get isReady => videoStatus == VideoStatus.ready;

  /// Check if video is processing
  bool get isProcessing => videoStatus == VideoStatus.processing;

  /// Check if video upload failed
  bool get isFailed => videoStatus == VideoStatus.failed;

  /// Check if video is uploading
  bool get isUploading => videoStatus == VideoStatus.uploading;

  /// Check if notes are available
  bool get hasNotes => notesUrl != null && notesUrl!.isNotEmpty;

  /// Check if video ID is available
  bool get hasVideo => youtubeVideoId != null && youtubeVideoId!.isNotEmpty && isReady;

  /// Get formatted upload date (e.g., "Mar 25, 2026")
  String get formattedUploadDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[uploadedAt.month - 1]} ${uploadedAt.day}, ${uploadedAt.year}';
  }

  @override
  String toString() {
    return 'Lecture(id: $id, number: $lectureNumber, topic: $topic)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lecture && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Video status constants
class VideoStatus {
  /// Video is ready to watch
  static const String ready = 'ready';

  /// Video is being processed
  static const String processing = 'processing';

  /// Video upload failed
  static const String failed = 'failed';

  /// Video is being uploaded
  static const String uploading = 'uploading';

  /// Unknown status (fallback)
  static const String unknown = 'unknown';
}
