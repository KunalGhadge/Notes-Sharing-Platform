import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/core/helper/custom_icon.dart';
import 'package:notehub/model/mini_user_model.dart';
import 'package:notehub/view/profile_screen/profile_user.dart';

class ConnectionAvatar extends StatelessWidget {
  final MiniUserModel? user;
  const ConnectionAvatar({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        width: Get.width,
        height: 60,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      );
    }
    return ListTile(
      onTap: () => Get.to(() => ProfileUser(username: user!.username)),
      leading: CustomAvatar(path: user!.profile, name: user!.displayName, radius: 24),
      title: Text(user!.displayName, style: AppTypography.subHead2.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(user!.institute, style: AppTypography.body4.copyWith(color: Colors.grey)),
      trailing: user!.isFollowedByUser
        ? Icon(Icons.check_circle_rounded, color: PrimaryColor.shade500)
        : Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
    );
  }
}
