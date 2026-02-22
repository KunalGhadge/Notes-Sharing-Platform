import 'package:flutter/foundation.dart';
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
  var officialUpdates = <DocumentModel>[].obs;
  RealtimeChannel? _stream;

  @override
  void onInit() {
    super.onInit();
    listenToUpdates();
  }

  @override
  void onClose() {
    _stream?.unsubscribe();
    super.onClose();
  }

  void listenToUpdates() {
    _stream = supabase
        .channel('public:documents')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'documents',
          callback: (payload) {
            fetchUpdates(); // Refresh on any change
          },
        )
        .subscribe();
  }

  Future<void> fetchUpdates() async {
    isLoading.value = true;
    try {
      final response = await supabase.from('documents').select('''
            *,
            profiles:user_id (id, username, display_name, profile_url),
            interactions:interactions(user_id, type),
            bookmarks:bookmarks(user_id)
          ''').order('created_at', ascending: false).limit(50);

      final mapped = _mapDocuments(response as List);
      // Sticky Sort: is_official DESC, created_at DESC
      mapped.sort((a, b) {
        if (a.isOfficial && !b.isOfficial) return -1;
        if (!a.isOfficial && b.isOfficial) return 1;
        return b.dateOfUpload.compareTo(a.dateOfUpload);
      });
      updates.value = mapped;

      // Explicitly fetch official updates for the Official Page
      fetchOfficialUpdates();

      isFetched.value = true;
      update();
    } on PostgrestException catch (e) {
      Toasts.showTostError(message: "Sync error: ${e.message}");
    } catch (e) {
      Toasts.showTostError(
          message: "We're currently unable to refresh the feed.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOfficialUpdates() async {
    try {
      final response = await supabase
          .from('documents')
          .select('''
            *,
            profiles:user_id (id, username, display_name, profile_url),
            interactions:interactions(user_id, type),
            bookmarks:bookmarks(user_id)
          ''')
          .eq('is_official', true)
          .order('created_at', ascending: false)
          .limit(20);

      officialUpdates.value = _mapDocuments(response as List);
    } catch (e) {
      debugPrint("Official fetch error: $e");
    }
  }

  List<DocumentModel> _mapDocuments(List response) {
    final List<DocumentModel> tmp = [];
    final currentUserId = HiveBoxes.userId;

    for (var doc in response) {
      final profile = doc['profiles'];
      // if (profile == null) continue; // Don't skip
      // Skip docs with no profile data

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
