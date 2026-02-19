import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/document_model.dart';
import 'package:notehub/service/file_caching.dart';
import 'package:notehub/view/widgets/toasts.dart';
import 'package:open_file/open_file.dart';

class DocumentController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var userDocs = <DocumentModel>[].obs;

  Future<void> fetchDocsForUsername({required String username}) async {
    try {
      final userResponse = await supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .single();

      final userId = userResponse['id'];
      await fetchDocsByUserId(userId);
    } catch (e) {
      print("Error fetching docs for $username: $e");
    }
  }

  Future<void> fetchDocsByUserId(String userId) async {
    isLoading.value = true;
    try {
      final response = await supabase
          .from('documents')
          .select('''
            *,
            profiles:user_id (id, username, display_name, profile_url),
            likes:likes(user_id),
            bookmarks:bookmarks(user_id)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      userDocs.clear();
      final currentUserId = HiveBoxes.userId;

      for (var doc in response) {
        final profile = doc['profiles'];
        final List likes = doc['likes'] ?? [];
        final List bookmarks = doc['bookmarks'] ?? [];

        final isLiked = likes.any((l) => l['user_id'] == currentUserId);
        final isBookmarked = bookmarks.any((b) => b['user_id'] == currentUserId);

        userDocs.add(DocumentModel(
          documentId: doc['id'].toString(),
          username: profile['username'],
          displayName: profile['display_name'] ?? "User",
          profile: profile['profile_url'] ?? "NA",
          isFollowedByUser: false,
          name: doc['name'],
          topic: doc['topic'] ?? "",
          description: doc['description'] ?? "",
          likes: doc['likes_count'] ?? 0,
          icon: doc['cover_url'] ?? "",
          iconName: "cover",
          dateOfUpload: DateTime.parse(doc['created_at']),
          documentName: doc['document_name'] ?? "document",
          document: doc['document_url'],
          isLiked: isLiked,
          isBookmarked: isBookmarked,
        ));
      }
    } catch (e) {
      print("Error fetching docs: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(DocumentModel doc) async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) return;

    try {
      if (doc.isLiked) {
        await supabase
            .from('likes')
            .delete()
            .match({'user_id': userId, 'document_id': doc.documentId});

        await supabase.rpc('decrement_likes', params: {'doc_id': doc.documentId});
      } else {
        await supabase
            .from('likes')
            .insert({'user_id': userId, 'document_id': doc.documentId});

        await supabase.rpc('increment_likes', params: {'doc_id': doc.documentId});
      }
      doc.isLiked = !doc.isLiked;
      doc.likes += doc.isLiked ? 1 : -1;
      update();
    } catch (e) {
      print("Error toggling like: $e");
      Toasts.showTostError(message: "Failed to update like");
    }
  }

  Future<void> toggleBookmark(DocumentModel doc) async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) return;

    try {
      if (doc.isBookmarked) {
        await supabase
            .from('bookmarks')
            .delete()
            .match({'user_id': userId, 'document_id': doc.documentId});
      } else {
        await supabase
            .from('bookmarks')
            .insert({'user_id': userId, 'document_id': doc.documentId});
      }
      doc.isBookmarked = !doc.isBookmarked;
      update();
    } catch (e) {
      print("Error toggling bookmark: $e");
      Toasts.showTostError(message: "Failed to update bookmark");
    }
  }

  void openDocument(String url, String name) async {
    String path = await saveAndOpenFile(uri: url, name: name);
    OpenFile.open(path);
  }
}
