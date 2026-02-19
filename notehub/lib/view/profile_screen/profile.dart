import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/profile_controller.dart';
import 'package:notehub/controller/showcase_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/view/profile_screen/widget/profile_header.dart';
import 'package:notehub/view/profile_screen/widget/profile_showcase.dart';
import 'package:notehub/view/settings_screen/settings_drawer.dart';
import 'package:notehub/view/widgets/refresher_widget.dart';
import 'package:shimmer/shimmer.dart';

class Profile extends StatefulWidget {
  final String username;
  const Profile({super.key, required this.username});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  void initState() {
    super.initState();
    Get.put(SettingsDrawerController());
    Get.put(ShowcaseController(), tag: widget.username);
    loadUserData();
  }

  Future<void> loadUserData() async {
    Get.find<ProfileController>().fetchUserData(username: HiveBoxes.username);
    final showcase = Get.find<ShowcaseController>(tag: widget.username);
    showcase.fetchProfilePosts(username: HiveBoxes.username);
    showcase.fetchSavedPosts(username: HiveBoxes.username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Get.find<SettingsDrawerController>().scaffoldKey,
      resizeToAvoidBottomInset: false,
      drawer: const SettingsDrawer(),
      body: RefresherWidget(
        onRefresh: loadUserData,
        child: Column(
          children: [
            const SafeArea(child: SizedBox(height: 10)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: Get.find<SettingsDrawerController>().openDrawer,
                    icon: Icon(Icons.settings_outlined, color: PrimaryColor.shade500, size: 28),
                  ),
                ],
              ),
            ),
            GetX<ProfileController>(builder: (controller) {
              if (controller.isLoading.value) {
                return Shimmer.fromColors(
                  baseColor: GrayscaleWhiteColors.almostWhite,
                  highlightColor: GrayscaleWhiteColors.white,
                  child: ProfileHeader(profileData: controller.user.value),
                );
              }
              return ProfileHeader(profileData: controller.user.value);
            }),
            Expanded(child: ProfileShowcase(username: widget.username)),
          ],
        ),
      ),
    );
  }
}
