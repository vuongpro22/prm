import 'package:flutter/material.dart';
import 'package:prm_project/database/database_helper.dart';
import 'package:prm_project/models/app_notification.dart';

class NotificationViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  int? _userId;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void setUserId(int? id) {
    if (_userId != id) {
      _userId = id;
      _notifications = [];
      if (id != null) {
        loadNotifications();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> loadNotifications() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final dbNotifications = await _dbHelper.getNotifications(_userId!);
      _notifications = dbNotifications;

      // Seed initial notification if empty
      if (_notifications.isEmpty) {
        await addNotification(
          'Chào mừng bạn đến với Luxura!',
          'Cảm ơn bạn đã tham gia Luxura Store. Hãy sử dụng mã khuyến mãi WELCOME10 để được giảm giá 10% cho đơn hàng đầu tiên của bạn!',
        );
        await addNotification(
          'Chương trình Khuyến mãi Hè đang diễn ra!',
          'Tiết kiệm cực lớn ngay hôm nay với mã giảm giá SUPERDEAL20 để được giảm 20% cho các đơn hàng!',
        );
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNotification(String title, String body) async {
    if (_userId == null) return;

    final newNotif = AppNotification(
      id: 'NTF-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );

    // Insert locally at top
    _notifications.insert(0, newNotif);
    notifyListeners();

    // Persist to database
    await _dbHelper.insertNotification(_userId!, newNotif);
  }

  Future<void> markAsRead(String notificationId) async {
    if (_userId == null) return;

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _dbHelper.markNotificationAsRead(_userId!, notificationId);
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _dbHelper.markAllNotificationsAsRead(_userId!);
  }

  Future<void> clearNotifications() async {
    if (_userId == null) return;

    _notifications = [];
    notifyListeners();
    await _dbHelper.clearNotifications(_userId!);
  }
}
