import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'exam_reminder' | 'lecture_uploaded' | 'general'
  final Map<String, dynamic> data;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.time,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'data': data,
    'time': time.toIso8601String(),
    'isRead': isRead,
  };

  // Emoji by type
  String get icon {
    switch (type) {
      case 'exam_reminder': return '📝';
      case 'lecture_uploaded': return '🎬';
      default: return '🔔';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  List<AppNotification> get examReminders =>
      _notifications.where((n) => n.type == 'exam_reminder').toList();

  List<AppNotification> get lectureUploads =>
      _notifications.where((n) => n.type == 'lecture_uploaded').toList();

  // ── Load from SharedPreferences ───────────────────────────────────────────
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('notifications') ?? [];
      _notifications = raw
          .map((s) => AppNotification.fromJson(jsonDecode(s)))
          .toList();
    } catch (_) {
      _notifications = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Mark one as read ──────────────────────────────────────────────────────
  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notifications[idx].isRead = true;
    notifyListeners();
    await _saveAll();
  }

  // ── Mark all as read ──────────────────────────────────────────────────────
  Future<void> markAllRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _saveAll();
  }

  // ── Delete one ────────────────────────────────────────────────────────────
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveAll();
  }

  // ── Clear all ─────────────────────────────────────────────────────────────
  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'notifications',
      _notifications.map((n) => jsonEncode(n.toJson())).toList(),
    );
  }
}