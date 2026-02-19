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
  DateTime dateOfUpload;
  String documentName;
  String document;
  bool isLiked;
  bool isBookmarked;
  bool isExternal;

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
    required this.icon,
    required this.iconName,
    required this.dateOfUpload,
    required this.documentName,
    required this.document,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isExternal = false,
  });

  static String verifyProfile(String? profileUrl, String displayName) {
    if (profileUrl == null || profileUrl == "NA" || profileUrl.isEmpty) {
      return "${AppMetaData.avatar_url}&name=$displayName";
    }
    return profileUrl;
  }
}
