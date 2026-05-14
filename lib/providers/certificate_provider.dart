/// Certificate Provider
library;

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

  List<Certificate> get certificates => _certificates;
  List<ExamHistory> get examHistory => _examHistory;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  int get certificatesEarned => _certificates.length;
  int get totalAttempts => _examHistory.length;
  int get examsPassed =>
      _examHistory.where((e) => e.isCompleted && e.isPassed).length;
  int get examsFailed =>
      _examHistory.where((e) => e.isCompleted && !e.isPassed).length;

  Future<void> fetchCertificates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getCertificates(),
        _apiService.getExamHistory(),
      ]);
      _certificates = results[0] as List<Certificate>;
      _examHistory = results[1] as List<ExamHistory>;
      if (kDebugMode) debugPrint('✅ Certs: ${_certificates.length}, History: ${_examHistory.length}');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ CertificateProvider error: $e');
      // ✅ Fixed: ApiException check instead of e.toString()
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Something went wrong. Please try again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchCertificates();
}