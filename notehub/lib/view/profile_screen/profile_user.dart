import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/profile_user_controller.dart';
import 'package:notehub/controller/showcase_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/core/meta/app_meta.dart';
import 'package:notehub/model/user_model.dart';
import 'package:notehub/view/profile_screen/widget/follower_widget.dart';
import 'package:notehub/view/profile_screen/widget/profile_showcase.dart';
import 'package:notehub/view/widgets/primary_button.dart';
import 'package:notehub/view/widgets/refresher_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:notehub/view/widgets/admin_badge.dart';

class ProfileUser extends StatefulWidget {
  final String username;
  const ProfileUser({super.key, required this.username});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  @override
  void initState() {
    super.initState();
    Get.put(ProfileUserController(), tag: widget.username);
    Get.put(ShowcaseController(), tag: widget.username);
    loadUserData();
  }

  Future<void> loadUserData() async {
    final myUsername = HiveBoxes.username.toLowerCase();
    final targetUsername = widget.username.toLowerCase();

    Get.find<ProfileUserController>(tag: widget.username)
        .fetchUserData(username: widget.username);
    final showcase = Get.find<ShowcaseController>(tag: widget.username);
    showcase.fetchProfilePosts(username: widget.username);

    if (myUsername == targetUsername) {
      showcase.fetchSavedPosts(username: widget.username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: PrimaryColor.shade500),
      ),
      extendBodyBehindAppBar: true,
      body: RefresherWidget(
        onRefresh: loadUserData,
        child: Column(
          children: [
            GetX<ProfileUserController>(
              tag: widget.username,
              builder: (controller) {
                if (controller.isLoading.value) {
                  return Shimmer.fromColors(
                    baseColor: GrayscaleWhiteColors.almostWhite,
                    highlightColor: GrayscaleWhiteColors.white,
                    child: ProfileHeader(
                      profileData: controller.profileData.value,
                    ),
                  );
                }
                return ProfileHeader(
                  profileData: controller.profileData.value,
                );
              },
            ),
            Expanded(child: ProfileShowcase(username: widget.username)),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final UserModel profileData;
  const ProfileHeader({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 100, 18, 16),
      child: Column(
        children: [
          TopSection(profileData: profileData),
          const SizedBox(height: 24),
          ButtonSection(
              profileData: profileData, usernameTag: profileData.username),
        ],
      ),
    );
  }
}

class TopSection extends StatelessWidget {
  final UserModel profileData;
  const TopSection({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _renderAvatar(profileData.profile, profileData.displayName),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FollowerWidget(
                      data: profileData.documents.toString(),
                      display: "Docs",
                    ),
                    FollowerWidget(
                      data: profileData.followers.toString(),
                      display: "Followers",
                    ),
                    FollowerWidget(
                      data: profileData.following.toString(),
                      display: "Following",
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                profileData.displayName,
                style: AppTypography.heading6
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              if (profileData.isAdmin)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: AdminBadge(),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: PrimaryColor.shade500),
              const SizedBox(width: 4),
              Text(
                profileData.institute,
                style: AppTypography.body3.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _renderAvatar(String profile, String name) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: profileData.isAdmin
              ? const Color(0xFFFFD700)
              : PrimaryColor.shade500,
          width: 2,
        ),
        boxShadow: profileData.isAdmin
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 10,
                )
              ]
            : null,
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: PrimaryColor.shade100,
        backgroundImage: NetworkImage(
          profile == "" || profile == "NA"
              ? "${AppMetaData.avatarUrl}&name=$name"
              : profile,
        ),
      ),
    );
  }
}

class ButtonSection extends StatelessWidget {
  final UserModel profileData;
  final String usernameTag;
  const ButtonSection(
      {super.key, required this.profileData, required this.usernameTag});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: GetX<ProfileUserController>(
        tag: usernameTag,
        builder: (controller) {
          return Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  onTap: () {
                    controller.follow(username: profileData.username);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      !controller.profileData.value.isFollowedByUser
                          ? "Follow"
                          : "Unfollow",
                      style: AppTypography.subHead3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  Share.share(
                    "Check out ${profileData.displayName}'s profile on ${AppMetaData.appName}! 📚 Find quality study notes and contribute to the community. Username: @${profileData.username}",
                    subject: "${profileData.displayName}'s Profile",
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PrimaryColor.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.share_outlined,
                      color: PrimaryColor.shade500, size: 24),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
