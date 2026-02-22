import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/view/profile_screen/widget/post_renderer.dart';
import 'package:notehub/controller/showcase_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/document_model.dart';

class ProfileTabController extends GetxController {
  var selectedIndex = 0.obs;

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }
}

class ProfileShowcase extends StatefulWidget {
  final String? username;
  const ProfileShowcase({super.key, this.username});

  @override
  State<ProfileShowcase> createState() => _ProfileShowcaseState();
}

class _ProfileShowcaseState extends State<ProfileShowcase>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileTabController profileTabController =
      Get.put(ProfileTabController());

  @override
  void initState() {
    super.initState();
    final myUsername = HiveBoxes.username.toLowerCase();
    final targetUsername = widget.username?.toLowerCase() ?? "";
    _tabController = TabController(
      length: myUsername == targetUsername ? 3 : 1,
      vsync: this,
    );

    _tabController.addListener(() {
      profileTabController.changeTabIndex(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showcaseController =
        Get.find<ShowcaseController>(tag: widget.username);
    final myUsername = HiveBoxes.username.toLowerCase();
    final targetUsername = widget.username?.toLowerCase() ?? "";
    final isMe = myUsername == targetUsername;

    return Column(
      children: [
        Obx(
          () => TabBar(
            controller: _tabController,
            isScrollable: isMe,
            indicatorColor: PrimaryColor.shade500,
            labelColor: PrimaryColor.shade500,
            unselectedLabelColor: Colors.grey,
            tabs: [
              const Tab(
                icon: Icon(Icons.grid_view_rounded),
                text: "My Notes",
              ),
              if (isMe) ...[
                const Tab(
                  icon: Icon(Icons.bookmark_rounded),
                  text: "Saved",
                ),
                const Tab(
                  icon: Icon(Icons.download_done_rounded),
                  text: "Downloads",
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Obx(() => PostsRenderer(
                    usernameTag: widget.username!,
                    posts: showcaseController.profilePosts,
                  )),
              if (isMe) ...[
                Obx(() => PostsRenderer(
                      usernameTag: widget.username!,
                      posts: showcaseController.savedPosts,
                    )),
                Obx(() {
                  final downloads = HiveBoxes.getDownloads()
                      .map((j) => DocumentModel.fromJson(j))
                      .toList();
                  return PostsRenderer(
                    usernameTag: widget.username!,
                    posts: downloads,
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
