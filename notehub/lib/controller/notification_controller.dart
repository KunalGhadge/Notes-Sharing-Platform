import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/view/widgets/toasts.dart';

class NotificationModel {
  final String id;
  final String senderName;
  final String senderProfile;
  final String type;
  final String? content;
  final DateTime createdAt;
  final bool isRead;
  final bool isGlobal;

  NotificationModel({
    required this.id,
    required this.senderName,
    required this.senderProfile,
    required this.type,
    this.content,
    required this.createdAt,
    required this.isRead,
    this.isGlobal = false,
  });
}

class NotificationController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var notifications = <NotificationModel>[].obs;
  RealtimeChannel? _channel;

  @override
  void onInit() {
    super.onInit();
    listenToNotifications();
  }

  @override
  void onClose() {
    _channel?.unsubscribe();
    super.onClose();
  }

  void listenToNotifications() {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) return;

    _channel = supabase
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final rec = payload.newRecord;
            if (rec['is_global'] == true || rec['receiver_id'] == userId) {
              _showLocalNotification(rec);
              fetchNotifications();
            }
          },
        )
        .subscribe();
  }

  Future<void> _showLocalNotification(Map<String, dynamic> record) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const android = AndroidNotificationDetails(
      'notes_channel',
      'Notes Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platform = NotificationDetails(android: android);

    await flutterLocalNotificationsPlugin.show(
      id: record['id'].hashCode,
      title: record['is_global'] == true
          ? 'Global Announcement'
          : 'New ${record['type']}',
      body: record['content'] ?? 'You have a new interaction on your notes!',
      notificationDetails: platform,
    );
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final userId = HiveBoxes.userId;
      if (userId.isEmpty) return;

      final response = await supabase
          .from('notifications')
          .select('*, profiles:sender_id (display_name, profile_url)')
          .or('receiver_id.eq.$userId,is_global.eq.true')
          .order('created_at', ascending: false);

      notifications.value =
          (response as List).where((n) => n['profiles'] != null).map((n) {
        final profile = n['profiles'];
        return NotificationModel(
          id: n['id'].toString(),
          senderName: profile['display_name'] ?? "Someone",
          senderProfile: profile['profile_url'] ?? "NA",
          type: n['type'],
          content: n['content'],
          createdAt: DateTime.parse(n['created_at']),
          isRead: n['is_read'],
          isGlobal: n['is_global'] ?? false,
        );
      }).toList();
    } on PostgrestException catch (e) {
      Toasts.showTostError(message: "Notification error: ${e.message}");
    } catch (e) {
      Toasts.showTostError(message: "Unexpected error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead() async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) return;
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('receiver_id', userId);
  }

  Future<void> broadcastAnnouncement(String title, String content) async {
    try {
      final senderId = HiveBoxes.userId;
      // Security check: Profile must have is_admin = true
      final profile = await supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', senderId)
          .single();
      if (profile['is_admin'] != true) {
        Toasts.showTostError(message: "Permission denied.");
        return;
      }

      await supabase.from('notifications').insert({
        'sender_id': senderId,
        'type': 'announcement',
        'content': "$title: $content",
        'is_global': true,
      });
      Toasts.showTostSuccess(message: "Announcement broadcasted!");
    } catch (e) {
      Toasts.showTostError(message: "Could not broadcast: $e");
    }
  }
}
