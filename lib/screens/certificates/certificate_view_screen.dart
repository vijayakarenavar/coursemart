library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/certificate.dart';
import '../../utils/app_colors.dart';

class CertificateViewScreen extends StatefulWidget {
  final Certificate cert;

  const CertificateViewScreen({super.key, required this.cert});

  @override
  State<CertificateViewScreen> createState() => _CertificateViewScreenState();
}

class _CertificateViewScreenState extends State<CertificateViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final url =
        'https://coursemart.edu-novaa.in/certificates/${widget.cert.certificateNumber}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.cert.certificateNumber,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
        ],
      ),
    );
  }
}