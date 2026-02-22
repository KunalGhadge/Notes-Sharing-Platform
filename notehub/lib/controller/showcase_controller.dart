import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/document_model.dart';
import 'package:notehub/view/widgets/toasts.dart';

class ShowcaseController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;

  var profilePosts = <DocumentModel>[].obs;
  var savedPosts = <DocumentModel>[].obs;

  Future<void> fetchProfilePosts({required String username}) async {
    isLoading.value = true;
    try {
      final userResponse = await supabase
          .from('profiles')
          .select('id')
          .ilike('username', username)
          .maybeSingle();

      if (userResponse == null) return;
      final userId = userResponse['id'];

      final response = await supabase.from('documents').select('''
            *,
            profiles:user_id (id, username, display_name, profile_url),
            interactions:interactions(user_id, type),
            bookmarks:bookmarks(user_id)
          ''').eq('user_id', userId).order('created_at', ascending: false);

      profilePosts.value = _mapDocuments(response);
    } on PostgrestException catch (e) {
      Toasts.showTostError(message: "Database error: ${e.message}");
    } catch (e) {
      Toasts.showTostError(message: "Unexpected error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSavedPosts({required String username}) async {
    isLoading.value = true;
    try {
      final userResponse = await supabase
          .from('profiles')
          .select('id')
          .ilike('username', username)
          .maybeSingle();

      if (userResponse == null) return;
      final userId = userResponse['id'];

      final bookmarkResponse = await supabase
          .from('bookmarks')
          .select('document_id')
          .eq('user_id', userId);

      final docIds =
          (bookmarkResponse as List).map((b) => b['document_id']).toList();

      if (docIds.isEmpty) {
        savedPosts.clear();
        return;
      }

      final response = await supabase.from('documents').select('''
            *,
            profiles:user_id (id, username, display_name, profile_url),
            interactions:interactions(user_id, type),
            bookmarks:bookmarks(user_id)
          ''').filter('id', 'in', docIds).order('created_at', ascending: false);

      savedPosts.value = _mapDocuments(response);
    } on PostgrestException catch (e) {
      Toasts.showTostError(message: "Database error: ${e.message}");
    } catch (e) {
      Toasts.showTostError(message: "Unexpected error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  List<DocumentModel> _mapDocuments(dynamic response) {
    final List<DocumentModel> tmp = [];
    final currentUserId = HiveBoxes.userId;

    for (var doc in (response as List)) {
      final profile = doc['profiles'];
      // if (profile == null) continue; // Don't skip
      final List interactions = doc['interactions'] ?? [];
      final List bookmarks = doc['bookmarks'] ?? [];

      final interaction = interactions
          .firstWhere((i) => i['user_id'] == currentUserId, orElse: () => null);

      final isLiked = interaction != null && interaction['type'] == 'like';
      final isDisliked =
          interaction != null && interaction['type'] == 'dislike';
      final isBookmarked = bookmarks.any((b) => b['user_id'] == currentUserId);

      tmp.add(DocumentModel(
        documentId: doc['id'].toString(),
        username: profile?['username'] ?? "unknown",
        displayName: profile?['display_name'] ?? "Contributor",
        profile: profile?['profile_url'] ?? "NA",
        isFollowedByUser: false,
        name: doc['name'] ?? "Untitled",
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
        isOfficial: doc['is_official'] ?? false,
        postType: doc['post_type'] ?? 'note',
      ));
    }
    return tmp;
  }
}
