import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/view/profile_screen/widget/post_renderer.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/helper/hive_boxes.dart';

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
    _tabController = TabController(
      length: HiveBoxes.username == widget.username ? 2 : 1,
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
    return Column(
      children: [
        Obx(
          () => TabBar(
            controller: _tabController,
            indicatorColor: PrimaryColor.shade500,
            labelColor: PrimaryColor.shade500,
            unselectedLabelColor: Colors.grey,
            tabs: [
              const Tab(
                icon: Icon(Icons.grid_view_rounded),
                text: "My Notes",
              ),
              if (HiveBoxes.username == widget.username)
                const Tab(
                  icon: Icon(Icons.bookmark_rounded),
                  text: "Saved",
                ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              PostsRenderer(
                usernameTag: widget.username!,
                isSaved: false,
              ),
              if (HiveBoxes.username == widget.username)
                PostsRenderer(
                  usernameTag: widget.username!,
                  isSaved: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
