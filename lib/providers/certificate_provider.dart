// lib/providers/certificate_provider.dart
// ✅ All getters match dashboard_screen.dart usage

import 'package:flutter/foundation.dart';
import '../models/certificate.dart';
import '../models/exam_history.dart';
import '../services/api_service.dart';

class CertificateProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Certificate> _certificates = [];
  List<ExamHistory> _examHistory = [];

  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters used in dashboard_screen.dart ─────────────────────────────────

  List<Certificate> get certificates => _certificates;
  List<ExamHistory> get examHistory => _examHistory;

  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  /// Tab label: "Certificates (N)"
  int get certificatesEarned => _certificates.length;

  /// Tab label: "Exam History (N)" — all attempts including in_progress
  int get totalAttempts => _examHistory.length;

  /// Summary card: Passed (completed + passed==true)
  int get examsPassed =>
      _examHistory.where((e) => e.isCompleted && e.isPassed).length;

  /// Summary card: Failed (completed + passed==false)
  int get examsFailed =>
      _examHistory.where((e) => e.isCompleted && !e.isPassed).length;

  // ── Fetch both on tab open ─────────────────────────────────────────────────

  Future<void> fetchCertificates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Run both in parallel
      final results = await Future.wait([
        _apiService.getCertificates(),
        _apiService.getExamHistory(),
      ]);
      _certificates = results[0] as List<Certificate>;
      _examHistory = results[1] as List<ExamHistory>;
      debugPrint('✅ Certs: ${_certificates.length}, History: ${_examHistory.length}');
    } catch (e) {
      debugPrint('❌ CertificateProvider error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchCertificates();
}