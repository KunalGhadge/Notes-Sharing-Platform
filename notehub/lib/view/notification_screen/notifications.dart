import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/notification_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/core/meta/app_meta.dart';
import 'package:intl/intl.dart';

class NotificationView extends StatelessWidget {
  NotificationView({super.key});

  final controller = Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {
    controller.fetchNotifications();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
              onPressed: () => controller.markAsRead(),
              child: const Text("Mark all as read")),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("No notifications yet",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return Container(
              color: notification.isRead
                  ? Colors.transparent
                  : PrimaryColor.shade100.withValues(alpha: 0.1),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(notification.senderProfile ==
                          "NA"
                      ? "${AppMetaData.avatarUrl}&name=${notification.senderName}"
                      : notification.senderProfile),
                ),
                title: RichText(
                  text: TextSpan(
                    style: AppTypography.body2.copyWith(color: Colors.black),
                    children: [
                      TextSpan(
                          text: notification.senderName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: _getNotificationText(notification)),
                    ],
                  ),
                ),
                subtitle: Text(
                    DateFormat.yMMMd().add_jm().format(notification.createdAt),
                    style: AppTypography.body4),
                trailing: !notification.isRead
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: PrimaryColor.shade500,
                            shape: BoxShape.circle))
                    : null,
              ),
            );
          },
        );
      }),
    );
  }

  String _getNotificationText(NotificationModel n) {
    switch (n.type) {
      case 'like':
        return " liked your note.";
      case 'comment':
        return " commented: '${n.content}'";
      case 'follow':
        return " started following you.";
      case 'new_post':
        return " uploaded a new note.";
      default:
        return " interacted with you.";
    }
  }
}
