import "package:hive/hive.dart";

part "user_model.g.dart";

@HiveType(typeId: 1)
class UserModel {
  @HiveField(8)
  final String? id;
  @HiveField(0)
  final String displayName;
  @HiveField(1)
  final String username;
  @HiveField(2)
  final String institute;
  @HiveField(3)
  final String profile;
  @HiveField(4)
  final int following;
  @HiveField(5)
  final int followers;
  @HiveField(6)
  final int documents;
  @HiveField(24)
  final bool isFollowedByUser;
  @HiveField(25)
  final bool isAdmin;
  @HiveField(9)
  final List<String> academicInterests;

  UserModel({
    this.id,
    required this.displayName,
    required this.username,
    required this.institute,
    required this.profile,
    this.isFollowedByUser = false,
    this.isAdmin = false,
    this.followers = 0,
    this.following = 0,
    this.documents = 0,
    this.academicInterests = const [],
  });

  UserModel copyWith({
    String? id,
    String? displayName,
    String? username,
    String? institute,
    String? profile,
    int? followers,
    int? following,
    int? documents,
    bool? isFollowedByUser,
    bool? isAdmin,
    List<String>? academicInterests,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      institute: institute ?? this.institute,
      profile: profile ?? this.profile,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      documents: documents ?? this.documents,
      isFollowedByUser: isFollowedByUser ?? this.isFollowedByUser,
      isAdmin: isAdmin ?? this.isAdmin,
      academicInterests: academicInterests ?? this.academicInterests,
    );
  }
}
