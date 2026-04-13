library;

class Certificate {
  final String id;
  final String certificateNumber;
  final String verificationCode;
  final String courseTitle;
  final String studentName;
  final String grade;
  final double percentage;
  final String status;
  final DateTime issuedAt;

  const Certificate({
    required this.id,
    required this.certificateNumber,
    required this.verificationCode,
    required this.courseTitle,
    required this.studentName,
    required this.grade,
    required this.percentage,
    required this.status,
    required this.issuedAt,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['_id'] ?? json['id'] ?? '',
      certificateNumber: json['certificateNumber'] ?? '',
      verificationCode: json['verificationCode'] ?? '',
      courseTitle: json['courseId'] is Map
          ? json['courseId']['title'] ?? 'Unknown Course'
          : 'Unknown Course',
      studentName: json['studentId'] is Map
          ? json['studentId']['name'] ?? 'Unknown'
          : 'Unknown',
      grade: json['grade'] ?? 'N/A',
      percentage: json['percentage'] != null          // ✅ fix 1
          ? double.tryParse(json['percentage'].toString()) ?? 0.0
          : 0.0,
      status: json['status'] ?? 'issued',
      issuedAt: json['issuedAt'] != null              // ✅ fix 2
          ? DateTime.tryParse(json['issuedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[issuedAt.month - 1]} ${issuedAt.day}, ${issuedAt.year}';
  }
}