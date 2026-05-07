/// Certificate View Screen
/// ✅ Bearer token header WebView मध्ये inject करतो
/// ✅ Direct certificate page open होतो (no login needed)
library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/certificate.dart';
import '../../services/secure_storage.dart';
import '../../utils/app_colors.dart';

class CertificateViewScreen extends StatefulWidget {
  final Certificate cert;

  const CertificateViewScreen({super.key, required this.cert});

  @override
  State<CertificateViewScreen> createState() => _CertificateViewScreenState();
}

class _CertificateViewScreenState extends State<CertificateViewScreen> {
  WebViewController? _controller; // ✅ nullable — ready झाल्यावरच use
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _controller = null; // reset
      });
    }

    final token = await SecureStorage().getAuthToken();

    // ✅ Certificate model मधला certificateUrl वापर (attemptId based)
    final url = widget.cert.certificateUrl;

    debugPrint('🔗 Certificate URL: $url');
    debugPrint('🔑 Token present: ${token != null}');

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('📄 Page started: $url');
            if (mounted) setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (url) {
            debugPrint('✅ Page finished: $url');
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('❌ WebView error: ${error.description}');
            if (mounted) setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
          onNavigationRequest: (request) {
            debugPrint('🔀 Navigation: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'text/html,application/xhtml+xml',
        },
      );

    if (mounted) {
      setState(() => _controller = controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Certificate',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Text(
              widget.cert.certificateNumber,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _initWebView,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ Controller ready झाल्यावरच WebViewWidget दाखव
          if (_controller != null)
            WebViewWidget(controller: _controller!),

          // Loading — controller नाही किंवा page load होत आहे
          if (_isLoading && !_hasError)
            Container(
              color: AppColors.bgOf(context),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.cyan),
                    SizedBox(height: 16),
                    Text(
                      'Loading certificate...',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // Error state
          if (_hasError)
            Container(
              color: AppColors.bgOf(context),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 64, color: AppColors.cyan),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load certificate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOf(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your internet connection and try again',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text2Of(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _initWebView,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}