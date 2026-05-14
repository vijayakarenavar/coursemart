import 'package:flutter_test/flutter_test.dart';
import 'package:coursemart_app/models/course.dart';
import 'package:coursemart_app/models/lecture.dart';
import 'package:coursemart_app/models/student.dart';

void main() {
  // ═══════════════════════════════════════════
  // COURSE MODEL TESTS
  // ═══════════════════════════════════════════
  group('Course Model Tests', () {
    test('Course.fromJson - valid JSON parse karto ka', () {
      final json = {
        '_id': 'course123',
        'title': 'Flutter Development',
        'description': 'Learn Flutter',
        'thumbnail': 'https://example.com/thumb.jpg',
        'duration': 30,
        'progress': 60,
        'totalLectures': 20,
        'completedLectures': 12,
        'scheduleStatus': 'in_progress',
      };

      final course = Course.fromJson(json);

      expect(course.id, 'course123');
      expect(course.title, 'Flutter Development');
      expect(course.progress, 60);
      expect(course.totalLectures, 20);
      expect(course.completedLectures, 12);
      expect(course.scheduleStatus, 'in_progress');
    });

    test('Course.fromJson - null/missing fields la default values miltat ka', () {
      final course = Course.fromJson({});

      expect(course.id, '');
      expect(course.title, 'Untitled Course');
      expect(course.progress, 0);
      expect(course.totalLectures, 0);
      expect(course.scheduleStatus, CourseStatus.notStarted);
    });

    test('Course - progressDecimal correct aahe ka', () {
      final course = Course.fromJson({'progress': 75});
      expect(course.progressDecimal, 0.75);
    });

    test('Course - remainingLectures correct aahe ka', () {
      final course = Course.fromJson({
        'totalLectures': 20,
        'completedLectures': 8,
      });
      expect(course.remainingLectures, 12);
    });

    test('Course - isCompleted correct aahe ka', () {
      final course = Course.fromJson({'scheduleStatus': 'completed'});
      expect(course.isCompleted, true);
      expect(course.isInProgress, false);
      expect(course.isNotStarted, false);
    });

    test('Course - isInProgress correct aahe ka', () {
      final course = Course.fromJson({'scheduleStatus': 'in_progress'});
      expect(course.isInProgress, true);
    });

    test('Course - isNotStarted correct aahe ka', () {
      final course = Course.fromJson({'scheduleStatus': 'not_started'});
      expect(course.isNotStarted, true);
    });

    test('Course - toJson correct aahe ka', () {
      final course = Course.fromJson({
        '_id': 'c1',
        'title': 'Test Course',
        'description': 'Desc',
        'thumbnail': 'thumb.jpg',
      });
      final json = course.toJson();
      expect(json['_id'], 'c1');
      expect(json['title'], 'Test Course');
    });

    test('Course - copyWith kaam karto ka', () {
      final course = Course.fromJson({'_id': 'c1', 'title': 'Old Title'});
      final updated = course.copyWith(title: 'New Title');
      expect(updated.title, 'New Title');
      expect(updated.id, 'c1');
    });

    test('Course - equality check karto ka', () {
      final c1 = Course.fromJson({'_id': 'same_id'});
      final c2 = Course.fromJson({'_id': 'same_id'});
      final c3 = Course.fromJson({'_id': 'diff_id'});
      expect(c1, equals(c2));
      expect(c1, isNot(equals(c3)));
    });

    test('Course - progress 0 asel tar progressDecimal 0.0 aahe ka', () {
      final course = Course.fromJson({'progress': 0});
      expect(course.progressDecimal, 0.0);
    });

    test('Course - progress 100 asel tar progressDecimal 1.0 aahe ka', () {
      final course = Course.fromJson({'progress': 100});
      expect(course.progressDecimal, 1.0);
    });
  });

  // ═══════════════════════════════════════════
  // LECTURE MODEL TESTS
  // ═══════════════════════════════════════════
  group('Lecture Model Tests', () {
    test('Lecture.fromJson - valid JSON parse karto ka', () {
      final json = {
        '_id': 'lec123',
        'lectureNumber': 1,
        'topic': 'Intro to Flutter',
        'videoStatus': 'ready',
        'uploadedAt': '2026-03-25T10:00:00.000Z',
        'trainerName': 'John Doe',
        'youtubeVideoId': 'abc123xyz',
        'notesUrl': 'https://example.com/notes.pdf',
      };

      final lecture = Lecture.fromJson(json);

      expect(lecture.id, 'lec123');
      expect(lecture.lectureNumber, 1);
      expect(lecture.topic, 'Intro to Flutter');
      expect(lecture.videoStatus, 'ready');
      expect(lecture.trainerName, 'John Doe');
      expect(lecture.youtubeVideoId, 'abc123xyz');
    });

    test('Lecture.fromJson - null/missing fields la default values miltat ka', () {
      final lecture = Lecture.fromJson({});

      expect(lecture.id, '');
      expect(lecture.topic, 'Untitled Lecture');
      expect(lecture.videoStatus, VideoStatus.unknown);
      expect(lecture.trainerName, 'Unknown Trainer');
      expect(lecture.youtubeVideoId, null);
    });

    test('Lecture - isReady correct aahe ka', () {
      final lecture = Lecture.fromJson({'videoStatus': 'ready'});
      expect(lecture.isReady, true);
      expect(lecture.isProcessing, false);
      expect(lecture.isFailed, false);
    });

    test('Lecture - isProcessing correct aahe ka', () {
      final lecture = Lecture.fromJson({'videoStatus': 'processing'});
      expect(lecture.isProcessing, true);
    });

    test('Lecture - isFailed correct aahe ka', () {
      final lecture = Lecture.fromJson({'videoStatus': 'failed'});
      expect(lecture.isFailed, true);
    });

    test('Lecture - isUploading correct aahe ka', () {
      final lecture = Lecture.fromJson({'videoStatus': 'uploading'});
      expect(lecture.isUploading, true);
    });

    test('Lecture - hasNotes - notes asel tar true aahe ka', () {
      final lecture = Lecture.fromJson({'notesUrl': 'https://example.com/notes.pdf'});
      expect(lecture.hasNotes, true);
    });

    test('Lecture - hasNotes - notes nasel tar false aahe ka', () {
      final lecture = Lecture.fromJson({'notesUrl': null});
      expect(lecture.hasNotes, false);
    });

    test('Lecture - hasVideo - ready + youtubeVideoId asel tar true aahe ka', () {
      final lecture = Lecture.fromJson({
        'videoStatus': 'ready',
        'youtubeVideoId': 'abc123',
      });
      expect(lecture.hasVideo, true);
    });

    test('Lecture - hasVideo - processing asel tar false aahe ka', () {
      final lecture = Lecture.fromJson({
        'videoStatus': 'processing',
        'youtubeVideoId': 'abc123',
      });
      expect(lecture.hasVideo, false);
    });

    test('Lecture - parts array madhu youtubeVideoId kadhato ka', () {
      final json = {
        '_id': 'lec1',
        'videoStatus': 'ready',
        'parts': [
          {'youtubeVideoId': 'partVideoId123'}
        ],
      };
      final lecture = Lecture.fromJson(json);
      expect(lecture.youtubeVideoId, 'partVideoId123');
    });

    test('Lecture - uploadedAt String parse karto ka', () {
      final lecture = Lecture.fromJson({
        'uploadedAt': '2026-03-25T10:00:00.000Z',
      });
      expect(lecture.uploadedAt.year, 2026);
      expect(lecture.uploadedAt.month, 3);
      expect(lecture.uploadedAt.day, 25);
    });

    test('Lecture - formattedUploadDate correct aahe ka', () {
      final lecture = Lecture.fromJson({
        'uploadedAt': '2026-03-25T10:00:00.000Z',
      });
      expect(lecture.formattedUploadDate, 'Mar 25, 2026');
    });

    test('Lecture - toJson correct aahe ka', () {
      final lecture = Lecture.fromJson({
        '_id': 'l1',
        'topic': 'Test Topic',
        'videoStatus': 'ready',
      });
      final json = lecture.toJson();
      expect(json['_id'], 'l1');
      expect(json['topic'], 'Test Topic');
    });

    test('Lecture - copyWith kaam karto ka', () {
      final lecture = Lecture.fromJson({'_id': 'l1', 'topic': 'Old Topic'});
      final updated = lecture.copyWith(topic: 'New Topic');
      expect(updated.topic, 'New Topic');
      expect(updated.id, 'l1');
    });

    test('Lecture - equality check karto ka', () {
      final l1 = Lecture.fromJson({'_id': 'same_id'});
      final l2 = Lecture.fromJson({'_id': 'same_id'});
      final l3 = Lecture.fromJson({'_id': 'diff_id'});
      expect(l1, equals(l2));
      expect(l1, isNot(equals(l3)));
    });
  });

  // ═══════════════════════════════════════════
  // STUDENT MODEL TESTS
  // ═══════════════════════════════════════════
  group('Student Model Tests', () {
    test('Student.fromJson - valid JSON parse karto ka', () {
      final json = {
        '_id': 'stu123',
        'name': 'Rahul Sharma',
        'rollNumber': 'CS2021001',
        'email': 'rahul@example.com',
        'collegeId': {'name': 'MIT College'},
        'username': 'rahul21',
        'createdAt': '2024-01-01',
        'enrolledCourses': [
          {'_id': 'c1', 'title': 'Flutter Dev'},
          {'_id': 'c2', 'title': 'React Native'},
        ],
      };

      final student = Student.fromJson(json);

      expect(student.id, 'stu123');
      expect(student.name, 'Rahul Sharma');
      expect(student.rollNumber, 'CS2021001');
      expect(student.email, 'rahul@example.com');
      expect(student.collegeName, 'MIT College');
      expect(student.enrolledCourses.length, 2);
    });

    test('Student.fromJson - null/missing fields la default values miltat ka', () {
      final student = Student.fromJson({});

      expect(student.id, '');
      expect(student.name, 'Unknown');
      expect(student.collegeName, 'Unknown College');
      expect(student.enrolledCourses, isEmpty);
    });

    test('Student - collegeId String asel tar handle karto ka', () {
      final student = Student.fromJson({'collegeId': 'Some College Name'});
      expect(student.collegeName, 'Some College Name');
    });

    test('Student - collegeId null asel tar default college name milto ka', () {
      final student = Student.fromJson({'collegeName': 'Backup College'});
      expect(student.collegeName, 'Backup College');
    });

    test('Student - enrolledCourses correctly parse hotat ka', () {
      final student = Student.fromJson({
        'enrolledCourses': [
          {'_id': 'c1', 'title': 'Course 1'},
          {'_id': 'c2', 'title': 'Course 2'},
        ],
      });
      expect(student.enrolledCourses.length, 2);
      expect(student.enrolledCourses[0].id, 'c1');
      expect(student.enrolledCourses[0].title, 'Course 1');
    });

    test('Student - toJson correct aahe ka', () {
      final student = Student.fromJson({
        '_id': 's1',
        'name': 'Test Student',
        'email': 'test@test.com',
      });
      final json = student.toJson();
      expect(json['_id'], 's1');
      expect(json['name'], 'Test Student');
    });

    test('Student - copyWith kaam karto ka', () {
      final student = Student.fromJson({'_id': 's1', 'name': 'Old Name'});
      final updated = student.copyWith(name: 'New Name');
      expect(updated.name, 'New Name');
      expect(updated.id, 's1');
    });

    test('Student - equality check karto ka', () {
      final s1 = Student.fromJson({'_id': 'same_id'});
      final s2 = Student.fromJson({'_id': 'same_id'});
      final s3 = Student.fromJson({'_id': 'diff_id'});
      expect(s1, equals(s2));
      expect(s1, isNot(equals(s3)));
    });
  });

  // ═══════════════════════════════════════════
  // ENROLLED COURSE MODEL TESTS
  // ═══════════════════════════════════════════
  group('EnrolledCourse Model Tests', () {
    test('EnrolledCourse.fromJson - valid JSON parse karto ka', () {
      final course = EnrolledCourse.fromJson({'_id': 'ec1', 'title': 'Flutter'});
      expect(course.id, 'ec1');
      expect(course.title, 'Flutter');
    });

    test('EnrolledCourse.fromJson - missing fields la defaults miltat ka', () {
      final course = EnrolledCourse.fromJson({});
      expect(course.id, '');
      expect(course.title, 'Unknown Course');
    });

    test('EnrolledCourse - toJson correct aahe ka', () {
      final course = EnrolledCourse.fromJson({'_id': 'ec1', 'title': 'Flutter'});
      final json = course.toJson();
      expect(json['_id'], 'ec1');
      expect(json['title'], 'Flutter');
    });
  });

  // ═══════════════════════════════════════════
  // VIDEO STATUS CONSTANTS TESTS
  // ═══════════════════════════════════════════
  group('VideoStatus Constants Tests', () {
    test('VideoStatus constants correct ahet ka', () {
      expect(VideoStatus.ready, 'ready');
      expect(VideoStatus.processing, 'processing');
      expect(VideoStatus.failed, 'failed');
      expect(VideoStatus.uploading, 'uploading');
      expect(VideoStatus.unknown, 'unknown');
    });
  });

  // ═══════════════════════════════════════════
  // COURSE STATUS CONSTANTS TESTS
  // ═══════════════════════════════════════════
  group('CourseStatus Constants Tests', () {
    test('CourseStatus constants correct ahet ka', () {
      expect(CourseStatus.notStarted, 'not_started');
      expect(CourseStatus.inProgress, 'in_progress');
      expect(CourseStatus.completed, 'completed');
    });
  });
}