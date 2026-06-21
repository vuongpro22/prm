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
          'Welcome to Luxura!',
          'Thank you for joining Luxura Store. Use promo code WELCOME10 to get 10% off your first purchase!',
        );
        await addNotification(
          'Summer Sale Active!',
          'Save big today with discount code SUPERDEAL20 for a 20% discount on orders!',
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
