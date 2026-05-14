/// Lecture data model
///
/// Represents a lecture within a course with video
/// status, optional notes, and multi-part support.
library;

/// Lecture Part model — एका lecture चा एक part
class LecturePart {
  final int partNumber;
  final String? youtubeVideoId;
  final String? embedUrl;
  final int duration; // seconds मध्ये
  final String videoStatus;
  final DateTime uploadedAt;

  const LecturePart({
    required this.partNumber,
    this.youtubeVideoId,
    this.embedUrl,
    required this.duration,
    required this.videoStatus,
    required this.uploadedAt,
  });

  factory LecturePart.fromJson(Map<String, dynamic> json) {
    DateTime uploadedDate;
    if (json['uploadedAt'] != null && json['uploadedAt'] is String) {
      uploadedDate = DateTime.tryParse(json['uploadedAt']) ?? DateTime.now();
    } else {
      uploadedDate = DateTime.now();
    }

    return LecturePart(
      partNumber: json['partNumber'] ?? 1,
      youtubeVideoId: json['youtubeVideoId'],
      embedUrl: json['embedUrl'],
      duration: json['duration'] ?? 0,
      videoStatus: json['videoStatus'] ?? VideoStatus.unknown,
      uploadedAt: uploadedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'partNumber': partNumber,
    'youtubeVideoId': youtubeVideoId,
    'embedUrl': embedUrl,
    'duration': duration,
    'videoStatus': videoStatus,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  bool get isReady => videoStatus == VideoStatus.ready;
  bool get hasVideo => youtubeVideoId != null && youtubeVideoId!.isNotEmpty && isReady;

  /// Duration formatted as "20:00" किंवा "1:05:00"
  String get formattedDuration {
    final h = duration ~/ 3600;
    final m = (duration % 3600) ~/ 60;
    final s = duration % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// Lecture model class
///
/// Contains all lecture-related data from the API.
/// Multi-part lectures साठी [parts] list वापरा.
class Lecture {
  final String id;
  final int lectureNumber;
  final String topic;
  final String videoStatus; // ready, processing, failed, uploading
  final DateTime uploadedAt;
  final String trainerName;

  // Optional fields (available in lecture details endpoint)
  final String? notesUrl;
  final String? courseTitle;

  // Multi-part support
  final List<LecturePart> parts;
  final int totalParts;
  final int totalDuration; // seconds

  // Legacy single-part (backward compat)
  final String? youtubeVideoId;

  const Lecture({
    required this.id,
    required this.lectureNumber,
    required this.topic,
    required this.videoStatus,
    required this.uploadedAt,
    required this.trainerName,
    this.notesUrl,
    this.courseTitle,
    this.parts = const [],
    this.totalParts = 0,
    this.totalDuration = 0,
    this.youtubeVideoId,
  });

  /// Create a Lecture from JSON map
  factory Lecture.fromJson(Map<String, dynamic> json) {
    DateTime uploadedDate;
    if (json['uploadedAt'] != null) {
      if (json['uploadedAt'] is String && (json['uploadedAt'] as String).isNotEmpty) {
        uploadedDate = DateTime.tryParse(json['uploadedAt']) ?? DateTime.now();
      } else if (json['uploadedAt'] is DateTime) {
        uploadedDate = json['uploadedAt'];
      } else {
        uploadedDate = DateTime.now();
      }
    } else {
      uploadedDate = DateTime.now();
    }

    // Parts parse करा
    final rawParts = json['parts'] as List<dynamic>?;
    final List<LecturePart> parts = rawParts != null
        ? rawParts
        .whereType<Map<String, dynamic>>()
        .map((p) => LecturePart.fromJson(p))
        .toList()
        : [];

    // Legacy youtubeVideoId — parts नसल्यास top-level वाचा
    String? youtubeVideoId = json['youtubeVideoId'] as String?;
    if ((youtubeVideoId == null || youtubeVideoId.isEmpty) && parts.isNotEmpty) {
      youtubeVideoId = parts.first.youtubeVideoId;
    }

    return Lecture(
      id: json['_id'] ?? json['id'] ?? '',
      lectureNumber: json['lectureNumber'] ?? 0,
      topic: json['topic'] ?? 'Untitled Lecture',
      videoStatus: json['videoStatus'] ?? VideoStatus.unknown,
      uploadedAt: uploadedDate,
      trainerName: json['trainerName'] ?? 'Unknown Trainer',
      notesUrl: json['notesUrl'],
      courseTitle: json['courseTitle'],
      parts: parts,
      totalParts: json['totalParts'] ?? parts.length,
      totalDuration: json['totalDuration'] ?? 0,
      youtubeVideoId: youtubeVideoId,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'lectureNumber': lectureNumber,
    'topic': topic,
    'videoStatus': videoStatus,
    'uploadedAt': uploadedAt.toIso8601String(),
    'trainerName': trainerName,
    'youtubeVideoId': youtubeVideoId,
    'notesUrl': notesUrl,
    'courseTitle': courseTitle,
    'parts': parts.map((p) => p.toJson()).toList(),
    'totalParts': totalParts,
    'totalDuration': totalDuration,
  };

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
    List<LecturePart>? parts,
    int? totalParts,
    int? totalDuration,
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
      parts: parts ?? this.parts,
      totalParts: totalParts ?? this.totalParts,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  // ── Status helpers ──────────────────────────────────────────────────────────

  bool get isReady => videoStatus == VideoStatus.ready;
  bool get isProcessing => videoStatus == VideoStatus.processing;
  bool get isFailed => videoStatus == VideoStatus.failed;
  bool get isUploading => videoStatus == VideoStatus.uploading;
  bool get hasNotes => notesUrl != null && notesUrl!.isNotEmpty;

  /// Multi-part आहे का?
  bool get isMultiPart => parts.length > 1;

  /// कमीत कमी एक ready part आहे का?
  bool get hasVideo {
    if (parts.isNotEmpty) {
      return parts.any((p) => p.hasVideo);
    }
    return youtubeVideoId != null && youtubeVideoId!.isNotEmpty && isReady;
  }

  /// Ready parts list
  List<LecturePart> get readyParts => parts.where((p) => p.hasVideo).toList();

  /// Total duration formatted
  String get formattedTotalDuration {
    final h = totalDuration ~/ 3600;
    final m = (totalDuration % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  /// Get formatted upload date (e.g., "Mar 25, 2026")
  String get formattedUploadDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[uploadedAt.month - 1]} ${uploadedAt.day}, ${uploadedAt.year}';
  }

  @override
  String toString() => 'Lecture(id: $id, number: $lectureNumber, topic: $topic, parts: ${parts.length})';

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
  static const String ready = 'ready';
  static const String processing = 'processing';
  static const String failed = 'failed';
  static const String uploading = 'uploading';
  static const String unknown = 'unknown';
}