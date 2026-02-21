import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/document_model.dart';
import 'package:notehub/service/file_caching.dart';
import 'package:notehub/view/widgets/toasts.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

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
    } catch (e) { /* silent */ }
    update();
  }

  Future<void> fetchDocsByUserId(String userId) async {
    isLoading.value = true;
    try {
      final response = await supabase
          .from('documents')
          .select('''
            *,
            profiles:user_id (id, username, display_name, profile_url),
            interactions:interactions(user_id, type),
            bookmarks:bookmarks(user_id)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      userDocs.value = _mapDocuments(response as List);
    } catch (e) { /* silent */ } finally {
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

      final interaction = interactions.firstWhere(
        (i) => i['user_id'] == currentUserId,
        orElse: () => null
      );

      final isLiked = interaction != null && interaction['type'] == 'like';
      final isDisliked = interaction != null && interaction['type'] == 'dislike';
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
      ));
    }
    return tmp;
  }

  Future<void> toggleLike(DocumentModel doc) async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) return;

    try {
      if (doc.isLiked) {
        await supabase.from('interactions').delete().match({'user_id': userId, 'document_id': doc.documentId});
        await supabase.rpc('decrement_likes', params: {'doc_id': doc.documentId});
        doc.likes -= 1;
      } else {
        if (doc.isDisliked) await toggleDislike(doc);
        await supabase.from('interactions').upsert({'user_id': userId, 'document_id': doc.documentId, 'type': 'like'});
        await supabase.rpc('increment_likes', params: {'doc_id': doc.documentId});
        doc.likes += 1;
        _createNotification(doc.documentId, 'like');
      }
      doc.isLiked = !doc.isLiked;
      update();
    } catch (e) {
      String msg = "Failed to update like";
      if (e is PostgrestException) msg = e.message;
      Toasts.showTostError(message: msg);
    }
  }

  Future<void> toggleDislike(DocumentModel doc) async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) return;

    try {
      if (doc.isDisliked) {
        await supabase.from('interactions').delete().match({'user_id': userId, 'document_id': doc.documentId});
        await supabase.rpc('decrement_dislikes', params: {'doc_id': doc.documentId});
        doc.dislikes -= 1;
      } else {
        if (doc.isLiked) await toggleLike(doc);
        await supabase.from('interactions').upsert({'user_id': userId, 'document_id': doc.documentId, 'type': 'dislike'});
        await supabase.rpc('increment_dislikes', params: {'doc_id': doc.documentId});
        doc.dislikes += 1;
      }
      doc.isDisliked = !doc.isDisliked;
      update();
    } catch (e) {
      String msg = "Failed to update dislike";
      if (e is PostgrestException) msg = e.message;
      Toasts.showTostError(message: msg);
    }
  }

  Future<void> toggleBookmark(DocumentModel doc) async {
    final userId = HiveBoxes.userId;
    if (userId.isEmpty) {
      Toasts.showTostError(message: "Please log in to bookmark resources");
      return;
    }

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
      String msg = "Failed to update bookmark";
      if (e is PostgrestException) msg = e.message;
      Toasts.showTostError(message: msg);
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
    } catch (e) { /* silent */ }
  }

  void openDocument(DocumentModel doc) async {
    if (doc.isExternal) {
      final uri = Uri.parse(doc.document);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Toasts.showTostError(message: "Our systems encountered an issue opening this link. Please verify it's a valid URL.");
      }
    } else {
      String path = await saveAndOpenFile(uri: doc.document, name: doc.documentName);
      OpenFile.open(path);
    }
  }
}
