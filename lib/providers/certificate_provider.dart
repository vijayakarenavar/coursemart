library;

import 'package:flutter/foundation.dart';
import '../models/certificate.dart';
import '../services/api_service.dart';

class CertificateProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Certificate> _certificates = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Certificate> get certificates => _certificates;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  int get count => _certificates.length;

  Future<void> fetchCertificates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _certificates = await _apiService.getCertificates();
      debugPrint('✅ Certificates loaded: ${_certificates.length}');
    } catch (e) {
      debugPrint('❌ Certificate fetch error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchCertificates();
}