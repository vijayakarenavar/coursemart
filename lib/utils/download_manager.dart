/// Download manager utility
///
/// Handles file downloads (PDF notes, etc.) with progress tracking
/// and proper error handling.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../config/api_config.dart';

/// Download manager callback
typedef DownloadProgressCallback = void Function(int received, int total);
typedef DownloadCompleteCallback = void Function(String filePath);
typedef DownloadErrorCallback = void Function(String error);

/// Download Manager
///
/// Handles file downloads with:
/// - Progress tracking
/// - Cancellation support
/// - Automatic file storage
/// - Error handling
class DownloadManager {
  /// Singleton instance
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  /// Dio instance for downloads
  final Dio _dio = Dio();

  /// Active downloads tracker
  final Map<String, CancelToken> _activeDownloads = {};

  /// Get application documents directory
  Future<Directory> _getDownloadDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Download a file (e.g., PDF notes)
  ///
  /// [url] - The URL to download from
  /// [fileName] - Name to save the file as
  /// [onProgress] - Progress callback (received, total)
  /// [onComplete] - Completion callback (file path)
  /// [onError] - Error callback (error message)
  ///
  /// Returns the file path on success
  Future<String> downloadFile({
    required String url,
    required String fileName,
    DownloadProgressCallback? onProgress,
    DownloadCompleteCallback? onComplete,
    DownloadErrorCallback? onError,
  }) async {
    try {
      // Create unique download ID
      final downloadId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create cancel token for this download
      final cancelToken = CancelToken();
      _activeDownloads[downloadId] = cancelToken;

      // Get download directory
      final directory = await _getDownloadDirectory();
      final filePath = '${directory.path}/$fileName';

      // Build full URL
      final fullUrl = url.startsWith('http')
          ? url
          : ApiConfig.buildMediaUrl(url);

      debugPrint('⬇️ Downloading: $fullUrl');
      debugPrint('📁 Saving to: $filePath');

      // Download file
      await _dio.download(
        fullUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
              '📊 Progress: ${(received / total * 100).toStringAsFixed(0)}%',
            );
            onProgress?.call(received, total);
          }
        },
        options: Options(
          receiveTimeout: AppConstants.requestTimeout,
          sendTimeout: AppConstants.requestTimeout,
        ),
      );

      // Remove from active downloads
      _activeDownloads.remove(downloadId);

      debugPrint('✅ Download complete: $filePath');
      onComplete?.call(filePath);

      return filePath;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('⏹️ Download cancelled');
        onError?.call('Download cancelled');
        throw Exception('Download cancelled');
      }

      debugPrint('❌ Download error: ${e.message}');
      final errorMsg = e.message ?? 'Download failed';
      onError?.call(errorMsg);
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('❌ Download error: $e');
      onError?.call(e.toString());
      throw Exception('Download failed: $e');
    }
  }

  /// Open a downloaded file
  ///
  /// [filePath] - Path to the file to open
  /// Returns OpenResult with status
  Future<OpenResult> openFile(String filePath) async {
    try {
      debugPrint('📂 Opening file: $filePath');

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      // Open file with appropriate app
      final result = await OpenFile.open(filePath);
      debugPrint('📄 File opened with status: ${result.type}');

      return result;
    } catch (e) {
      debugPrint('❌ Error opening file: $e');
      rethrow;
    }
  }

  /// Download and open file in one step
  ///
  /// [url] - The URL to download from
  /// [fileName] - Name to save the file as
  /// [onProgress] - Progress callback
  Future<void> downloadAndOpen({
    required String url,
    required String fileName,
    DownloadProgressCallback? onProgress,
  }) async {
    final filePath = await downloadFile(
      url: url,
      fileName: fileName,
      onProgress: onProgress,
    );

    await openFile(filePath);
  }

  /// Cancel an active download
  ///
  /// [downloadId] - ID of the download to cancel
  void cancelDownload(String downloadId) {
    if (_activeDownloads.containsKey(downloadId)) {
      _activeDownloads[downloadId]!.cancel();
      _activeDownloads.remove(downloadId);
      debugPrint('⏹️ Download cancelled: $downloadId');
    }
  }

  /// Cancel all active downloads
  void cancelAllDownloads() {
    for (final entry in _activeDownloads.entries) {
      entry.value.cancel();
    }
    _activeDownloads.clear();
    debugPrint('⏹️ All downloads cancelled');
  }

  /// Get count of active downloads
  int get activeDownloadCount => _activeDownloads.length;

  /// Check if there are active downloads
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;

  /// Delete a downloaded file
  ///
  /// [filePath] - Path to the file to delete
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ File deleted: $filePath');
      }
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
      rethrow;
    }
  }

  /// Get list of downloaded files
  Future<List<File>> getDownloadedFiles() async {
    try {
      final directory = await _getDownloadDirectory();
      final files = directory.listSync();

      return files
          .whereType<File>()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting files: $e');
      return [];
    }
  }

  /// Clear all downloaded files
  Future<void> clearDownloads() async {
    try {
      final files = await getDownloadedFiles();
      for (final file in files) {
        await file.delete();
      }
      debugPrint('🗑️ All downloads cleared');
    } catch (e) {
      debugPrint('❌ Error clearing downloads: $e');
      rethrow;
    }
  }
}
