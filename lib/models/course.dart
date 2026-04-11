/// Course data model
///
/// Represents a course enrolled by a student with
/// progress tracking and lecture count.
library;

/// Course model class
///
/// Contains all course-related data from the API
class Course {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final int duration; // Duration in days/weeks (API dependent)
  final int progress; // Progress percentage (0-100)
  final int totalLectures;
  final int completedLectures;
  final String scheduleStatus; // not_started, in_progress, completed

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    this.duration = 0,
    this.progress = 0,
    this.totalLectures = 0,
    this.completedLectures = 0,
    this.scheduleStatus = CourseStatus.notStarted,
  });

  /// Create a Course from JSON map
  ///
  /// Handles null safety and provides default values
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled Course',
      description: json['description'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? 0,
      progress: json['progress'] ?? 0,
      totalLectures: json['totalLectures'] ?? 0,
      completedLectures: json['completedLectures'] ?? 0,
      scheduleStatus: json['scheduleStatus'] ?? CourseStatus.notStarted,
    );
  }

  /// Convert Course to JSON map
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'duration': duration,
      'progress': progress,
      'totalLectures': totalLectures,
      'completedLectures': completedLectures,
      'scheduleStatus': scheduleStatus,
    };
  }

  /// Create a copy of Course with updated fields
  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnail,
    int? duration,
    int? progress,
    int? totalLectures,
    int? completedLectures,
    String? scheduleStatus,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      progress: progress ?? this.progress,
      totalLectures: totalLectures ?? this.totalLectures,
      completedLectures: completedLectures ?? this.completedLectures,
      scheduleStatus: scheduleStatus ?? this.scheduleStatus,
    );
  }

  /// Check if course is not started
  bool get isNotStarted => scheduleStatus == CourseStatus.notStarted;

  /// Check if course is in progress
  bool get isInProgress => scheduleStatus == CourseStatus.inProgress;

  /// Check if course is completed
  bool get isCompleted => scheduleStatus == CourseStatus.completed;

  /// Get progress as a decimal (0.0 to 1.0)
  double get progressDecimal => progress / 100.0;

  /// Get remaining lectures count
  int get remainingLectures => totalLectures - completedLectures;

  @override
  String toString() {
    return 'Course(id: $id, title: $title, progress: $progress%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Course status constants
class CourseStatus {
  static const String notStarted = 'not_started';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
}
