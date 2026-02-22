import 'package:notehub/core/meta/app_meta.dart';

class DocumentModel {
  String username;
  String displayName;
  String profile;
  String name;
  bool isFollowedByUser;
  String description;
  String documentId;
  String topic;
  String icon;
  String iconName;
  int likes;
  int dislikes;
  DateTime dateOfUpload;
  String? documentName;
  String? document;
  bool isLiked;
  bool isDisliked;
  bool isBookmarked;
  bool isExternal;
  bool isOfficial;
  String postType;

  DocumentModel({
    required this.username,
    required this.displayName,
    required this.profile,
    required this.isFollowedByUser,
    required this.name,
    required this.topic,
    required this.description,
    required this.documentId,
    required this.likes,
    this.dislikes = 0,
    required this.icon,
    required this.iconName,
    required this.dateOfUpload,
    this.documentName,
    this.document,
    this.isLiked = false,
    this.isDisliked = false,
    this.isBookmarked = false,
    this.isExternal = false,
    this.isOfficial = false,
    this.postType = 'note',
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'display_name': displayName,
      'profile_url': profile,
      'is_followed': isFollowedByUser,
      'name': name,
      'topic': topic,
      'description': description,
      'id': documentId,
      'likes_count': likes,
      'dislikes_count': dislikes,
      'cover_url': icon,
      'icon_name': iconName,
      'created_at': dateOfUpload.toIso8601String(),
      'document_name': documentName,
      'document_url': document,
      'is_liked': isLiked,
      'is_disliked': isDisliked,
      'is_bookmarked': isBookmarked,
      'is_external': isExternal,
      'is_official': isOfficial,
      'post_type': postType,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      username: json['username'] ?? "unknown",
      displayName: json['display_name'] ?? "User",
      profile: json['profile_url'] ?? "NA",
      isFollowedByUser: json['is_followed'] ?? false,
      name: json['name'] ?? "",
      topic: json['topic'] ?? "",
      description: json['description'] ?? "",
      documentId: json['id'].toString(),
      likes: json['likes_count'] ?? 0,
      dislikes: json['dislikes_count'] ?? 0,
      icon: json['cover_url'] ?? "",
      iconName: json['icon_name'] ?? "cover",
      dateOfUpload: DateTime.parse(json['created_at']),
      documentName: json['document_name'],
      document: json['document_url'],
      isLiked: json['is_liked'] ?? false,
      isDisliked: json['is_disliked'] ?? false,
      isBookmarked: json['is_bookmarked'] ?? false,
      isExternal: json['is_external'] ?? false,
      isOfficial: json['is_official'] ?? false,
      postType: json['post_type'] ?? 'note',
    );
  }

  static String verifyProfile(String? profileUrl, String displayName) {
    if (profileUrl == null || profileUrl == "NA" || profileUrl.isEmpty) {
      return "${AppMetaData.avatarUrl}&name=$displayName";
    }
    return profileUrl;
  }
}
