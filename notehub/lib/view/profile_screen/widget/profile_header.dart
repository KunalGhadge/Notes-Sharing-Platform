import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/model/user_model.dart';
import 'package:notehub/view/connection_screen/connection.dart';
import 'package:notehub/view/profile_screen/widget/follower_widget.dart';
import 'package:notehub/view/profile_screen/widget/edit_profile_dialog.dart';
import 'package:notehub/view/widgets/primary_button.dart';
import 'package:notehub/core/helper/custom_icon.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel profileData;
  const ProfileHeader({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopSection(profileData: profileData),
          const SizedBox(height: 16),
          if (profileData.academicInterests.isNotEmpty)
            _renderInterests(),
          const SizedBox(height: 24),
          const ButtonSection(),
        ],
      ),
    );
  }

  Widget _renderInterests() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: profileData.academicInterests.map((interest) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: PrimaryColor.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PrimaryColor.shade200),
        ),
        child: Text(
          interest,
          style: AppTypography.body4.copyWith(color: PrimaryColor.shade900, fontWeight: FontWeight.w500),
        ),
      )).toList(),
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
              CustomAvatar(path: profileData.profile, name: profileData.displayName, radius: 40),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FollowerWidget(
                      data: profileData.documents.toString(),
                      display: "Docs",
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => Connection(
                              username: profileData.username,
                              type: ConnectionType.followers,
                            ));
                      },
                      child: FollowerWidget(
                        data: profileData.followers.toString(),
                        display: "Followers",
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => Connection(
                              username: profileData.username,
                              type: ConnectionType.following,
                            ));
                      },
                      child: FollowerWidget(
                        data: profileData.following.toString(),
                        display: "Following",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profileData.displayName,
            style: AppTypography.heading6.copyWith(fontWeight: FontWeight.bold),
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
}

class ButtonSection extends StatelessWidget {
  const ButtonSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              onTap: () => Get.dialog(EditProfileDialog()),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Edit Profile",
                  style: AppTypography.subHead3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PrimaryColor.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.share_outlined, color: PrimaryColor.shade500, size: 24),
          ),
        ],
      ),
    );
  }
}
