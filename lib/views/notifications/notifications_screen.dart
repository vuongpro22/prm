import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:prm_project/viewmodels/notification_viewmodel.dart';
import 'package:prm_project/views/theme/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifVm = Provider.of<NotificationViewModel>(context);
    final notifications = notifVm.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('T H Ô N G  B Á O'),
        actions: [
          if (notifications.isNotEmpty) ...[
            TextButton(
              onPressed: () => notifVm.markAllAsRead(),
              child: const Text('ĐỌC TẤT CẢ', style: TextStyle(color: AppTheme.secondaryTeal, fontSize: 12)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.accentRose),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa thông báo'),
                    content: const Text('Bạn có muốn xóa toàn bộ lịch sử thông báo không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('HỦY'),
                      ),
                      TextButton(
                        onPressed: () {
                          notifVm.clearNotifications();
                          Navigator.pop(context);
                        },
                        child: const Text('XÓA', style: TextStyle(color: AppTheme.accentRose)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 72, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(fontSize: 18, color: AppTheme.textMain, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chúng tôi sẽ thông báo cho bạn tại đây khi có giao dịch phát sinh.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final formattedTime = DateFormat('MMM dd, hh:mm a').format(notif.timestamp);

                return Card(
                  color: notif.isRead ? AppTheme.darkSurface.withOpacity(0.5) : AppTheme.darkSurface,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: notif.isRead ? Colors.transparent : AppTheme.primaryNeon.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: notif.isRead
                          ? AppTheme.textMuted.withOpacity(0.15)
                          : AppTheme.primaryNeon.withOpacity(0.15),
                      child: Icon(
                        notif.isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: notif.isRead ? AppTheme.textMuted : AppTheme.primaryNeon,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                              color: AppTheme.textMain,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        notif.body,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                      ),
                    ),
                    onTap: () {
                      if (!notif.isRead) {
                        notifVm.markAsRead(notif.id);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
