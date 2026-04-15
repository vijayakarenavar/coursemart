// lib/models/exam_history.dart
// ✅ Matches actual API response (Postman confirmed)
// ✅ All getters used in dashboard_screen.dart work correctly

class ExamHistory {
  final String id;
  final int attemptNumber;
  final String courseId;
  final String courseTitle;
  final String status; // "completed" | "in_progress"

  final int? obtainedMarks;
  final int? totalMarksValue;
  final double? percentageValue;
  final bool? passedValue;
  final String? gradeValue;
  final bool? certificateEligible;
  final DateTime? submittedAt;
  final int? timeTaken;

  const ExamHistory({
    required this.id,
    required this.attemptNumber,
    required this.courseId,
    required this.courseTitle,
    required this.status,
    this.obtainedMarks,
    this.totalMarksValue,
    this.percentageValue,
    this.passedValue,
    this.gradeValue,
    this.certificateEligible,
    this.submittedAt,
    this.timeTaken,
  });

  factory ExamHistory.fromJson(Map<String, dynamic> json) {
    final totalScore = json['totalScore'] as Map<String, dynamic>?;

    return ExamHistory(
      id: json['_id'] ?? '',
      attemptNumber: json['attemptNumber'] ?? 1,
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? 'Unknown Course',
      status: json['status'] ?? 'in_progress',
      obtainedMarks: totalScore?['obtainedMarks'] as int?,
      totalMarksValue: totalScore?['totalMarks'] as int?,
      percentageValue: totalScore?['percentage'] != null
          ? double.tryParse(totalScore!['percentage'].toString())
          : null,
      passedValue: json['passed'] as bool?,
      gradeValue: json['grade'] as String?,
      certificateEligible: json['certificateEligible'] as bool?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'])
          : null,
      timeTaken: json['timeTaken'] as int?,
    );
  }

  // ── Getters that match dashboard_screen.dart usage ─────────────────────────

  /// e.score → obtained marks
  int get score => obtainedMarks ?? 0;

  /// e.totalMarks → total marks
  int get totalMarks => totalMarksValue ?? 0;

  /// e.percentage → non-nullable (used with .toStringAsFixed(1))
  double get percentage => percentageValue ?? 0.0;

  /// e.isPassed → bool
  bool get isPassed => passedValue ?? false;

  /// e.grade → non-nullable String
  String get grade => gradeValue ?? 'F';

  /// e.hasCertificate → bool
  bool get hasCertificate => certificateEligible ?? false;

  /// e.formattedDate → "Apr 13, 2026" or "In Progress"
  String get formattedDate {
    if (submittedAt == null) return 'In Progress';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[submittedAt!.month - 1]} ${submittedAt!.day}, ${submittedAt!.year}';
  }

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
}