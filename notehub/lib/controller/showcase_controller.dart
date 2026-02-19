import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/document_model.dart';

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
          .eq('username', username)
          .single();

      final userId = userResponse['id'];

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

      profilePosts.value = _mapDocuments(response);
    } catch (e) {
      print("Error fetching profile posts: $e");
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
          .eq('username', username)
          .single();

      final userId = userResponse['id'];

      final bookmarkResponse = await supabase
          .from('bookmarks')
          .select('document_id')
          .eq('user_id', userId);

      final docIds = (bookmarkResponse as List).map((b) => b['document_id']).toList();

      if (docIds.isEmpty) {
        savedPosts.clear();
        return;
      }

      final response = await supabase
          .from('documents')
          .select('''
            *,
            profiles:user_id (id, username, display_name, profile_url),
            likes:likes(user_id),
            bookmarks:bookmarks(user_id)
          ''')
          .inFilter('id', docIds)
          .order('created_at', ascending: false);

      savedPosts.value = _mapDocuments(response);
    } catch (e) {
      print("Error fetching saved posts: $e");
    } finally {
      isLoading.value = false;
    }
  }

  List<DocumentModel> _mapDocuments(dynamic response) {
    final List<DocumentModel> tmp = [];
    final currentUserId = HiveBoxes.userId;

    for (var doc in response) {
      final profile = doc['profiles'];
      final List likes = doc['likes'] ?? [];
      final List bookmarks = doc['bookmarks'] ?? [];

      final isLiked = likes.any((l) => l['user_id'] == currentUserId);
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
        icon: doc['cover_url'] ?? "",
        iconName: "cover",
        dateOfUpload: DateTime.parse(doc['created_at']),
        documentName: doc['document_name'] ?? "document",
        document: doc['document_url'],
        isLiked: isLiked,
        isBookmarked: isBookmarked,
        isExternal: doc['is_external'] ?? false,
      ));
    }
    return tmp;
  }
}
