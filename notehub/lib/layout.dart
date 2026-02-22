import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/bottom_navigation_controller.dart';
import 'package:notehub/controller/document_controller.dart';
import 'package:notehub/controller/download_controller.dart';
import 'package:notehub/controller/profile_controller.dart';
import 'package:notehub/controller/profile_user_controller.dart';
import 'package:notehub/controller/showcase_controller.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/view/bottom_footer/bottom_footer.dart';

import 'package:notehub/controller/remote_config_controller.dart';

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  @override
  void initState() {
    super.initState();
    Get.put(RemoteConfigController());
    Get.put(ProfileController());
    Get.put(ProfileUserController());
    Get.put(ShowcaseController());
    Get.put(DocumentController());
    Get.put(DownloadController());
    Get.put(BottomNavigationController());
    loadData();
  }

  void loadData() async {
    if (HiveBoxes.username.isNotEmpty) {
      Get.find<ProfileController>().fetchUserData(username: HiveBoxes.username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetX<BottomNavigationController>(
      builder: (controller) => Scaffold(
        resizeToAvoidBottomInset: false,
        body: controller.page[controller.currentPage.value],
        bottomNavigationBar: const BottomFooter(),
      ),
    );
  }
}
