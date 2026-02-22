import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/view/widgets/toasts.dart';

class CommentModel {
  final String id;
  final String? parentId;
  final bool isAdmin;
  final String content;
  final String displayName;
  final String profileUrl;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    this.parentId,
    this.isAdmin = false,
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
      final response = await supabase.from('comments').select('''
            *,
            profiles:user_id (id, username, display_name, profile_url, is_admin)
          ''').eq('document_id', docId).order('created_at', ascending: false);

      comments.value =
          (response as List).where((c) => c['profiles'] != null).map((c) {
        final profile = c['profiles'];
        return CommentModel(
          id: c['id'].toString(),
          parentId: c['parent_id']?.toString(),
          isAdmin: profile['is_admin'] ?? false,
          content: c['content'],
          displayName: profile['display_name'] ?? "User",
          profileUrl: profile['profile_url'] ?? "NA",
          createdAt: DateTime.parse(c['created_at']),
        );
      }).toList();
    } on PostgrestException catch (e) {
      Toasts.showTostError(message: "Comment sync error: ${e.message}");
    } catch (e) {
      Toasts.showTostError(message: "Could not load comments.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> postComment(String docId, String content,
      {String? parentId}) async {
    if (content.trim().isEmpty) return;
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) {
      Toasts.showTostError(message: "Please log in to comment.");
      return;
    }

    final tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";
    final newComment = CommentModel(
      id: tempId,
      parentId: parentId,
      content: content.trim(),
      displayName: HiveBoxes.displayName,
      profileUrl: HiveBoxes.profileUrl,
      createdAt: DateTime.now(),
      isAdmin: false, // Temporary
    );

    // Optimistic insert at top
    comments.insert(0, newComment);
    update();

    try {
      final response = await supabase
          .from('comments')
          .insert({
            'document_id': docId,
            'user_id': userId,
            'parent_id': parentId,
            'content': content.trim(),
          })
          .select()
          .single();

      // Replace temp with actual server data
      final index = comments.indexWhere((c) => c.id == tempId);
      if (index != -1) {
        comments[index] = CommentModel(
          id: response['id'].toString(),
          parentId: response['parent_id']?.toString(),
          content: response['content'],
          displayName: HiveBoxes.displayName,
          profileUrl: HiveBoxes.profileUrl,
          createdAt: DateTime.parse(response['created_at']),
          isAdmin:
              false, // We assume the current user is handled by badges differently or fetch again
        );
      }

      _createNotification(docId, parentId == null ? 'comment' : 'reply');
    } catch (e) {
      comments.removeWhere((c) => c.id == tempId);
      update();
      Toasts.showTostError(message: "Comment failed to post.");
    }
  }

  Future<void> deleteComment(String commentId) async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) {
      Toasts.showTostError(message: "Please log in to delete comments.");
      return;
    }

    try {
      await supabase.from('comments').delete().eq('id', commentId);
      comments.removeWhere((c) => c.id == commentId);
      update();
      Toasts.showTostSuccess(message: "Comment deleted.");
    } catch (e) {
      Toasts.showTostError(message: "Failed to delete comment: $e");
    }
  }

  Future<void> _createNotification(String docId, String type) async {
    try {
      final senderId = HiveBoxes.userId;
      final docData = await supabase
          .from('documents')
          .select('user_id')
          .eq('id', docId)
          .maybeSingle();
      if (docData == null) return;

      final receiverId = docData['user_id'];
      if (senderId == receiverId) return;

      await supabase.from('notifications').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'document_id': docId,
        'type': type,
        'content': type == 'reply'
            ? 'replied to your comment'
            : 'commented on your note',
      });
    } catch (e) {/* silent */}
  }
}
