/// Certificate View Screen
/// ✅ Bearer token header WebView मध्ये inject करतो
/// ✅ Direct certificate page open होतो (no login needed)
/// ✅ Download → फोनच्या Downloads folder मध्ये save (blob + regular <a download> दोन्ही)
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/certificate.dart';
import '../../services/secure_storage.dart';
import '../../utils/app_colors.dart';
import '../../utils/download_manager.dart';

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
  String? _lastHandledBlobUrl; // duplicate triggers टाळण्यासाठी
  String? _token; // ✅ blob fetch साठी (cookies/session सोबत वापरता येईल)

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
    _token = token;

    // ✅ Certificate model मधला certificateUrl वापर (attemptId based)
    final url = widget.cert.certificateUrl;

    if (kDebugMode) debugPrint('🔗 Certificate URL: $url');
    if (kDebugMode) debugPrint('🔑 Token present: ${token != null}');

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'CertDownloader',
        onMessageReceived: _handleBlobDownload,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (kDebugMode) debugPrint('📄 Page started: $url');
            if (mounted) setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (url) async {
            if (kDebugMode) debugPrint('✅ Page finished: $url');
            if (mounted) setState(() => _isLoading = false);

            // ✅ Download interceptor inject करा (blob + regular <a download>)
            await _injectDownloadInterceptor();
          },
          onWebResourceError: (error) {
            if (kDebugMode) debugPrint('❌ WebView error: ${error.description}');
            if (mounted) setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
          onNavigationRequest: (request) {
            final navUrl = request.url;
            if (kDebugMode) debugPrint('🔀 Navigation: $navUrl');

            // ✅ blob: URL असेल तर — WebView ला navigate करू देऊ नका,
            // त्याऐवजी JS ने fetch करून base64 म्हणून आपल्याकडे आणा
            if (navUrl.startsWith('blob:')) {
              if (_lastHandledBlobUrl != navUrl) {
                _lastHandledBlobUrl = navUrl;
                _fetchBlobAndSend(navUrl);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    controller.loadRequest(
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

  /// 🔹 Page मध्ये JS inject करतो जो download clicks intercept करतो
  /// — blob: URLs आणि regular <a download> links दोन्ही handle करतो
  Future<void> _injectDownloadInterceptor() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      await controller.runJavaScript('''
        (function() {
          if (window._certDownloadInterceptorInstalled) return;
          window._certDownloadInterceptorInstalled = true;

          const originalClick = HTMLAnchorElement.prototype.click;
          HTMLAnchorElement.prototype.click = function() {
            const href = this.href || '';

            // ✅ Case 1: blob: URL — fetch करून base64 म्हणून पाठवा
            if (href.startsWith('blob:')) {
              fetch(href)
                .then(res => res.blob())
                .then(blob => {
                  const reader = new FileReader();
                  reader.onloadend = function() {
                    const base64 = reader.result.split(',')[1];
                    CertDownloader.postMessage(base64);
                  };
                  reader.readAsDataURL(blob);
                });
              return; // default download cancel
            }

            // ✅ Case 2: regular link with download attribute (PDF वगैरे)
            if (this.hasAttribute('download') &&
                (href.toLowerCase().includes('.pdf') ||
                 href.toLowerCase().includes('certificate') ||
                 href.toLowerCase().includes('download'))) {
              fetch(href, { credentials: 'include' })
                .then(res => res.blob())
                .then(blob => {
                  const reader = new FileReader();
                  reader.onloadend = function() {
                    const base64 = reader.result.split(',')[1];
                    CertDownloader.postMessage(base64);
                  };
                  reader.readAsDataURL(blob);
                });
              return; // default download cancel
            }

            return originalClick.apply(this, arguments);
          };
        })();
      ''');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ JS injection failed: $e');
    }
  }
  /// 🔹 blob: URL ला page च्या JS context मध्ये fetch करून
  /// base64 म्हणून CertDownloader channel वर पाठवतो
  Future<void> _fetchBlobAndSend(String blobUrl) async {
    final controller = _controller;
    if (controller == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading certificate...')),
      );
    }

    try {
      // JS string मध्ये safe टाकण्यासाठी escape करा
      final escapedUrl = blobUrl.replaceAll("'", "\\'");

      await controller.runJavaScript('''
      fetch('$escapedUrl')
        .then(res => res.blob())
        .then(blob => {
          const reader = new FileReader();
          reader.onloadend = function() {
            const base64 = reader.result.split(',')[1];
            CertDownloader.postMessage(base64);
          };
          reader.readAsDataURL(blob);
        })
        .catch(err => {
          console.error('Blob fetch failed:', err);
        });
    ''');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Blob fetch JS failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  /// 🔹 base64 PDF data फोनच्या Downloads मध्ये save
  Future<void> _handleBlobDownload(JavaScriptMessage message) async {
    if (kDebugMode) debugPrint('⬇️ Download data received');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading certificate...')),
      );
    }

    try {
      final bytes = base64Decode(message.message);
      final fileName =
          '${DownloadManager.sanitizeFileName(widget.cert.certificateNumber)}.pdf';

      await DownloadManager().saveBytesToDownloads(fileName, bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Certificate saved to Downloads')),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
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
          if (_controller != null)
            WebViewWidget(controller: _controller!),

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