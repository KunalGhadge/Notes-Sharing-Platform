import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/view/widgets/toasts.dart';

class CommentModel {
  final String id;
  final String content;
  final String displayName;
  final String profileUrl;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.content,
    required this.displayName,
    required this.profileUrl,
    required this.createdAt,
  });
}

class CommentController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var comments = <CommentModel>[].obs;

  Future<void> fetchComments(String docId) async {
    isLoading.value = true;
    try {
      final response = await supabase
          .from('comments')
          .select('*, profiles:user_id (display_name, profile_url)')
          .eq('document_id', docId)
          .order('created_at', ascending: false);

      comments.value = (response as List).where((c) => c['profiles'] != null).map((c) {
        final profile = c['profiles'];
        return CommentModel(
          id: c['id'].toString(),
          content: c['content'],
          displayName: profile['display_name'] ?? "User",
          profileUrl: profile['profile_url'] ?? "NA",
          createdAt: DateTime.parse(c['created_at']),
        );
      }).toList();
    } catch (e) { /* silent */ } finally {
      isLoading.value = false;
    }
  }

  Future<void> postComment(String docId, String content) async {
    if (content.trim().isEmpty) return;

    try {
      final userId = HiveBoxes.userId;
      await supabase.from('comments').insert({
        'document_id': docId,
        'user_id': userId,
        'content': content.trim(),
      });
      fetchComments(docId);
      _createNotification(docId, 'comment', content);
    } catch (e) {
      Toasts.showTostError(message: "Failed to post comment");
    }
  }

  Future<void> _createNotification(String docId, String type, String content) async {
    try {
      final docData = await supabase
          .from('documents')
          .select('user_id')
          .eq('id', docId)
          .maybeSingle();
      if (docData == null) return;

      final receiverId = docData['user_id'];
      final senderId = HiveBoxes.userId;
      if (receiverId == senderId) return;

      await supabase.from('notifications').insert({
        'receiver_id': receiverId,
        'sender_id': senderId,
        'document_id': docId,
        'type': type,
        'content': content,
      });
    } catch (e) { /* silent */ }
  }
}
