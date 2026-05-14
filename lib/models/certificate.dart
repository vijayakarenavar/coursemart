/// Certificate Model
/// ✅ API response नुसार correct field names
library;

class Certificate {
  final String id;
  final String certificateNumber;
  final String courseName;
  final String collegeName;
  final String attemptId;
  final DateTime issuedDate;

  const Certificate({
    required this.id,
    required this.certificateNumber,
    required this.courseName,
    required this.collegeName,
    required this.attemptId,
    required this.issuedDate,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['_id'] ?? json['id'] ?? '',
      certificateNumber: json['certificateNumber'] ?? '',
      courseName: json['courseName'] ?? 'Unknown Course',
      collegeName: json['collegeName'] ?? '',
      attemptId: json['attemptId'] ?? '',
      issuedDate: json['issuedDate'] != null
          ? DateTime.tryParse(json['issuedDate']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[issuedDate.month - 1]} ${issuedDate.day}, ${issuedDate.year}';
  }

  // ✅ Website certificate URL — attemptId वापरतो
  String get certificateUrl =>
      'https://coursemart.edu-novaa.in/student/certificate/$attemptId';
}