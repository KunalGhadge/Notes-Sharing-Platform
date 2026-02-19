import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/document_model.dart';
import 'package:notehub/view/widgets/toasts.dart';

class HomeController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var isFetched = false.obs;

  var updates = <DocumentModel>[].obs;

  Future<void> fetchUpdates() async {
    isFetched.value = true;
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
          .order('created_at', ascending: false)
          .limit(50);

      updates.clear();
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
        ));
      }

      updates.value = tmp;
      update();
    } catch (e) {
      print("HomeController: Error in fetching updates: ${e.toString()}");
      Toasts.showTostError(message: "Error fetching documents");
    } finally {
      isLoading.value = false;
    }
  }
}
