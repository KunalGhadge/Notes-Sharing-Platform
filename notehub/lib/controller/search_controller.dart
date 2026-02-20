import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/document_model.dart';

class AppSearchController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var results = <DocumentModel>[].obs;

  Future<void> searchDocuments(String query, {String? topic}) async {
    if (query.isEmpty && topic == null) {
      results.clear();
      return;
    }

    isLoading.value = true;
    try {
      var request = supabase
          .from('documents')
          .select('''
            *,
            profiles:user_id (id, username, display_name, profile_url),
            interactions:interactions(user_id, type),
            bookmarks:bookmarks(user_id)
          ''');

      if (query.isNotEmpty) {
        request = request.ilike('name', '%$query%');
      }

      if (topic != null && topic != 'All') {
        request = request.eq('topic', topic);
      }

      final response = await request.order('created_at', ascending: false);
      results.value = _mapDocuments(response);
    } catch (e) { /* silent */ } finally {
      isLoading.value = false;
    }
  }

  List<DocumentModel> _mapDocuments(dynamic response) {
    final List<DocumentModel> tmp = [];
    final currentUserId = HiveBoxes.userId;

    for (var doc in response) {
      final profile = doc['profiles'];
      final List interactions = doc['interactions'] ?? [];
      final List bookmarks = doc['bookmarks'] ?? [];

      final interaction = interactions.firstWhere(
        (i) => i['user_id'] == currentUserId,
        orElse: () => null
      );

      final isLiked = interaction != null && interaction['type'] == 'like';
      final isDisliked = interaction != null && interaction['type'] == 'dislike';
      final isBookmarked = bookmarks.any((b) => b['user_id'] == currentUserId);

      tmp.add(DocumentModel(
        documentId: doc['id'].toString(),
        username: profile['username'],
        displayName: profile['display_name'] ?? "User",
        profile: profile['profile_url'] ?? "NA",
        isFollowedByUser: false,
        name: doc['name'],
        topic: doc['topic'] ?? "",
        description: doc['description'] ?? "",
        likes: doc['likes_count'] ?? 0,
        dislikes: doc['dislikes_count'] ?? 0,
        icon: doc['cover_url'] ?? "",
        iconName: "cover",
        dateOfUpload: DateTime.parse(doc['created_at']),
        documentName: doc['document_name'] ?? "document",
        document: doc['document_url'],
        isLiked: isLiked,
        isDisliked: isDisliked,
        isBookmarked: isBookmarked,
        isExternal: doc['is_external'] ?? false,
      ));
    }
    return tmp;
  }
}
