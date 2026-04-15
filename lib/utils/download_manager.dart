/// Download manager utility
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';

typedef DownloadProgressCallback = void Function(int received, int total);
typedef DownloadCompleteCallback = void Function(String filePath);
typedef DownloadErrorCallback = void Function(String error);

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  Dio get _dio => ApiService().dio;
  final Map<String, CancelToken> _activeDownloads = {};

  Future<Directory> _getDownloadDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// ✅ Check if file already downloaded
  Future<String?> getExistingFilePath(String fileName) async {
    final directory = await _getDownloadDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    if (await file.exists()) return filePath;
    return null;
  }

  Future<String> downloadFile({
    required String url,
    required String fileName,
    DownloadProgressCallback? onProgress,
    DownloadCompleteCallback? onComplete,
    DownloadErrorCallback? onError,
  }) async {
    try {
      final downloadId = DateTime.now().millisecondsSinceEpoch.toString();
      final cancelToken = CancelToken();
      _activeDownloads[downloadId] = cancelToken;

      final directory = await _getDownloadDirectory();
      final filePath = '${directory.path}/$fileName';

      final fullUrl = url.startsWith('http')
          ? url
          : ApiConfig.buildMediaUrl(url);

      debugPrint('⬇️ Downloading: $fullUrl');
      debugPrint('📁 Saving to: $filePath');

      await _dio.download(
        fullUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint('📊 Progress: ${(received / total * 100).toStringAsFixed(0)}%');
            onProgress?.call(received, total);
          }
        },
        options: Options(
          receiveTimeout: AppConstants.requestTimeout,
          sendTimeout: AppConstants.requestTimeout,
        ),
      );

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

  void cancelDownload(String downloadId) {
    if (_activeDownloads.containsKey(downloadId)) {
      _activeDownloads[downloadId]!.cancel();
      _activeDownloads.remove(downloadId);
      debugPrint('⏹️ Download cancelled: $downloadId');
    }
  }

  void cancelAllDownloads() {
    for (final entry in _activeDownloads.entries) {
      entry.value.cancel();
    }
    _activeDownloads.clear();
    debugPrint('⏹️ All downloads cancelled');
  }

  int get activeDownloadCount => _activeDownloads.length;
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;

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