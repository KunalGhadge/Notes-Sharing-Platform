import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';

class NotificationModel {
  final String id;
  final String senderName;
  final String senderProfile;
  final String type;
  final String? content;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.senderName,
    required this.senderProfile,
    required this.type,
    this.content,
    required this.createdAt,
    required this.isRead,
  });
}

class NotificationController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var notifications = <NotificationModel>[].obs;

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final userId = HiveBoxes.userId;
      final response = await supabase
          .from('notifications')
          .select('*, profiles:sender_id (display_name, profile_url)')
          .eq('receiver_id', userId)
          .order('created_at', ascending: false);

      notifications.value = (response as List)
          .where((n) => n['profiles'] != null)
          .map((n) {
        final profile = n['profiles'];
        return NotificationModel(
          id: n['id'].toString(),
          senderName: profile['display_name'] ?? "Someone",
          senderProfile: profile['profile_url'] ?? "NA",
          type: n['type'],
          content: n['content'],
          createdAt: DateTime.parse(n['created_at']),
          isRead: n['is_read'],
        );
      }).toList();
    } catch (e) { /* silent */ } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead() async {
     final userId = HiveBoxes.userId;
     await supabase.from('notifications').update({'is_read': true}).eq('receiver_id', userId);
  }
}
