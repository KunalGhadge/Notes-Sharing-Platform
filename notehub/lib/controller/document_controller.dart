import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/document_model.dart';
import 'package:notehub/service/file_caching.dart';
import 'package:notehub/view/widgets/toasts.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:notehub/controller/home_controller.dart';

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
          .maybeSingle();

      if (userResponse != null) {
        final userId = userResponse['id'];
        await fetchDocsByUserId(userId);
      }
    } catch (e) {
      /* silent */
    }
    update();
  }

  Future<void> fetchDocsByUserId(String userId) async {
    isLoading.value = true;
    try {
      final response = await supabase.from('documents').select('''
            *,
            profiles:user_id (id, username, display_name, profile_url),
            interactions:interactions(user_id, type),
            bookmarks:bookmarks(user_id)
          ''').eq('user_id', userId).order('created_at', ascending: false);

      userDocs.value = _mapDocuments(response as List);
    } on PostgrestException catch (e) {
      Toasts.showTostError(message: "Feed error: ${e.message}");
    } catch (e) {
      Toasts.showTostError(message: "Unexpected error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  List<DocumentModel> _mapDocuments(List response) {
    final List<DocumentModel> tmp = [];
    final currentUserId = HiveBoxes.userId;

    for (var doc in response) {
      final profile = doc['profiles'];
      if (profile == null) continue; // Skip docs with no profile data

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
        username: profile['username'] ?? "unknown",
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
        isOfficial: doc['is_official'] ?? false,
        postType: doc['post_type'] ?? 'note',
      ));
    }
    return tmp;
  }

  Future<void> toggleLike(DocumentModel doc) async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) return;

    // Optimistic Update
    final wasLiked = doc.isLiked;
    final originalLikes = doc.likes;

    doc.isLiked = !doc.isLiked;
    doc.likes += doc.isLiked ? 1 : -1;
    update();

    try {
      if (wasLiked) {
        await supabase
            .from('interactions')
            .delete()
            .match({'user_id': userId, 'document_id': doc.documentId});
        await supabase
            .rpc('decrement_likes', params: {'doc_id': doc.documentId});
      } else {
        if (doc.isDisliked) {
          await toggleDislike(
              doc); // Re-recursive call will handle its own optic
        }
        await supabase.from('interactions').upsert(
            {'user_id': userId, 'document_id': doc.documentId, 'type': 'like'});
        await supabase
            .rpc('increment_likes', params: {'doc_id': doc.documentId});
        _createNotification(doc.documentId, 'like');
      }
    } on PostgrestException catch (e) {
      // Revert on error
      doc.isLiked = wasLiked;
      doc.likes = originalLikes;
      update();
      Toasts.showTostError(message: "Could not update like: ${e.message}");
    } catch (e) {
      doc.isLiked = wasLiked;
      doc.likes = originalLikes;
      update();
      Toasts.showTostError(message: "An unexpected error occurred: $e");
    }
  }

  Future<void> toggleDislike(DocumentModel doc) async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) return;

    // Optimistic Update
    final wasDisliked = doc.isDisliked;
    final originalDislikes = doc.dislikes;

    doc.isDisliked = !doc.isDisliked;
    doc.dislikes += doc.isDisliked ? 1 : -1;
    update();

    try {
      if (wasDisliked) {
        await supabase
            .from('interactions')
            .delete()
            .match({'user_id': userId, 'document_id': doc.documentId});
        await supabase
            .rpc('decrement_dislikes', params: {'doc_id': doc.documentId});
      } else {
        if (doc.isLiked) {
          await toggleLike(doc);
        }
        await supabase.from('interactions').upsert({
          'user_id': userId,
          'document_id': doc.documentId,
          'type': 'dislike'
        });
        await supabase
            .rpc('increment_dislikes', params: {'doc_id': doc.documentId});
      }
    } on PostgrestException catch (e) {
      // Revert
      doc.isDisliked = wasDisliked;
      doc.dislikes = originalDislikes;
      update();
      Toasts.showTostError(message: "Could not update dislike: ${e.message}");
    } catch (e) {
      doc.isDisliked = wasDisliked;
      doc.dislikes = originalDislikes;
      update();
      Toasts.showTostError(message: "An unexpected error occurred: $e");
    }
  }

  Future<void> toggleBookmark(DocumentModel doc) async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) {
      Toasts.showTostError(message: "Please log in to bookmark resources");
      return;
    }

    final originalState = doc.isBookmarked;
    doc.isBookmarked = !doc.isBookmarked;
    update(); // Optimistic UI

    try {
      if (originalState) {
        await supabase
            .from('bookmarks')
            .delete()
            .match({'user_id': userId, 'document_id': doc.documentId});
      } else {
        await supabase
            .from('bookmarks')
            .insert({'user_id': userId, 'document_id': doc.documentId});
      }
    } catch (e) {
      doc.isBookmarked = originalState;
      update();
      Toasts.showTostError(message: "Bookmark sync failed");
    }
  }

  Future<void> deleteDocument(DocumentModel doc) async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty || doc.username != HiveBoxes.username) {
      Toasts.showTostError(message: "Permission denied.");
      return;
    }

    try {
      isLoading.value = true;
      // 1. Delete from Storage if it's a direct upload
      if (!doc.isExternal &&
          doc.document != null &&
          doc.document!.contains('storage/v1/object/public')) {
        try {
          final uri = Uri.parse(doc.document!);
          final path = uri.pathSegments
              .sublist(uri.pathSegments.indexOf('documents') + 1)
              .join('/');
          await supabase.storage.from('documents').remove([path]);
        } catch (storageError) {
          debugPrint("Storage cleanup minor error: $storageError");
        }
      }

      // 2. Delete from Database (Cascades to comments, likes, notifications)
      await supabase.from('documents').delete().eq('id', doc.documentId);

      Toasts.showTostSuccess(message: "Document deleted successfully.");

      // Refresh global states
      Get.find<HomeController>().fetchUpdates();
      // If we are in detail view, go back
      if (Get.currentRoute.contains('Document')) {
        Get.back();
      }
    } on PostgrestException catch (e) {
      Toasts.showTostError(message: "Delete failed: ${e.message}");
    } catch (e) {
      Toasts.showTostError(message: "An unexpected error occurred: $e");
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> _createNotification(String docId, String type) async {
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
      });
    } catch (e) {
      /* silent */
    }
  }

  void openDocument(DocumentModel doc) async {
    if (doc.isExternal) {
      if (doc.document == null) return;
      final uri = Uri.parse(doc.document!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Toasts.showTostError(
            message:
                "Our systems encountered an issue opening this link. Please verify it's a valid URL.");
      }
    } else {
      if (doc.document == null) {
        Toasts.showTostError(message: "No document attached to this post");
        return;
      }
      String path = await saveAndOpenFile(
          uri: doc.document!, name: doc.documentName ?? 'document');
      OpenFile.open(path);
    }
  }

  void _syncWithHome() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().update();
      }
    } catch (e) {
      /* silent */
    }
  }

  @override
  void update([List<Object>? ids, bool condition = true]) {
    super.update(ids, condition);
    _syncWithHome();
  }
}
