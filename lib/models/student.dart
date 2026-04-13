/// Student data model
///
/// Represents a student user with profile information
/// and enrolled courses.
library;

/// Student model class
///
/// Contains all student-related data from the API
class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String email;
  final String collegeName;
  final List<EnrolledCourse> enrolledCourses;

  const Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.email,
    required this.collegeName,
    this.enrolledCourses = const [],
  });

  /// Create a Student from JSON map
  ///
  /// Handles null safety and provides default values
  factory Student.fromJson(Map<String, dynamic> json) {
    // ✅ collegeId object मधून name काढा
    String collegeName = 'Unknown College';
    if (json['collegeId'] != null) {
      if (json['collegeId'] is Map) {
        collegeName = json['collegeId']['name'] ?? 'Unknown College';
      } else if (json['collegeId'] is String) {
        collegeName = json['collegeId'];
      }
    } else if (json['collegeName'] != null) {
      collegeName = json['collegeName'];
    }

    return Student(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      rollNumber: json['rollNumber'] ?? '',
      email: json['email'] ?? '',
      collegeName: collegeName,
      enrolledCourses: json['enrolledCourses'] != null
          ? (json['enrolledCourses'] as List)
          .map((course) => EnrolledCourse.fromJson(course))
          .toList()
          : [],
    );
  }

  /// Convert Student to JSON map
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'rollNumber': rollNumber,
      'email': email,
      'collegeName': collegeName,
      'enrolledCourses': enrolledCourses.map((c) => c.toJson()).toList(),
    };
  }

  /// Create a copy of Student with updated fields
  Student copyWith({
    String? id,
    String? name,
    String? rollNumber,
    String? email,
    String? collegeName,
    List<EnrolledCourse>? enrolledCourses,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      email: email ?? this.email,
      collegeName: collegeName ?? this.collegeName,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
    );
  }

  @override
  String toString() {
    return 'Student(id: $id, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Simplified course model for enrolled courses list in profile
class EnrolledCourse {
  final String id;
  final String title;

  const EnrolledCourse({required this.id, required this.title});

  /// Create from JSON
  factory EnrolledCourse.fromJson(Map<String, dynamic> json) {
    return EnrolledCourse(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Unknown Course',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'_id': id, 'title': title};
  }
}