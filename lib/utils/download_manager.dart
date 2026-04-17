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

  Future<String?> getExistingFilePath(String fileName) async {
    final directory = await _getDownloadDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    if (!await file.exists()) return null;

    try {
      final bytes = await file.openRead(0, 4).first;
      if (bytes.length >= 4 &&
          bytes[0] == 0x25 && bytes[1] == 0x50 &&
          bytes[2] == 0x44 && bytes[3] == 0x46) {
        return filePath;
      }
    } catch (_) {}

    await file.delete();
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

      final downloadDio = Dio();

      await downloadDio.download(
        fullUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress?.call(received, total);
          }
        },
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: AppConstants.requestTimeout,
          sendTimeout: AppConstants.requestTimeout,
          headers: {
            'Accept': 'application/pdf,*/*',
          },
        ),
      );

      final file = File(filePath);
      final fileSize = await file.length();

      if (fileSize < 100) {
        await file.delete();
        throw Exception('Downloaded file is too small — likely an error page');
      }

      final bytes = await file.openRead(0, 4).first;

      if (bytes.length < 4 || bytes[0] != 0x25 || bytes[1] != 0x50 ||
          bytes[2] != 0x44 || bytes[3] != 0x46) {
        await file.delete();
        throw Exception('Downloaded file is not a valid PDF.');
      }

      _activeDownloads.remove(downloadId);
      onComplete?.call(filePath);

      return filePath;

    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        onError?.call('Download cancelled');
        throw Exception('Download cancelled');
      }
      final errorMsg = e.message ?? 'Download failed';
      onError?.call(errorMsg);
      throw Exception(errorMsg);
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  void cancelDownload(String downloadId) {
    if (_activeDownloads.containsKey(downloadId)) {
      _activeDownloads[downloadId]!.cancel();
      _activeDownloads.remove(downloadId);
    }
  }

  void cancelAllDownloads() {
    for (final entry in _activeDownloads.entries) {
      entry.value.cancel();
    }
    _activeDownloads.clear();
  }

  int get activeDownloadCount => _activeDownloads.length;
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;

  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
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
      return [];
    }
  }

  Future<void> clearDownloads() async {
    try {
      final files = await getDownloadedFiles();
      for (final file in files) {
        await file.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
}