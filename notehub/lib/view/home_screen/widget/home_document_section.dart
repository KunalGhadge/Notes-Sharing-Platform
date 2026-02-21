import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:notehub/controller/home_controller.dart';
import 'package:notehub/core/config/color.dart';

import 'package:notehub/view/widgets/post_card.dart';
import 'package:notehub/view/widgets/refresher_widget.dart';
import 'package:shimmer/shimmer.dart';

class HomeDocumentSection extends StatelessWidget {
  const HomeDocumentSection({super.key});

  Future<void> _handleRefresh() async {
    var controller = Get.find<HomeController>();

    await controller.fetchUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return RefresherWidget(
      onRefresh: () async {
        await _handleRefresh();
      },
      child: GetX<HomeController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => Shimmer.fromColors(
                baseColor: GrayscaleWhiteColors.almostWhite,
                highlightColor: GrayscaleWhiteColors.white,
                child: Container(
                  height: 200,
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }

          if (controller.updates.isEmpty) {
            return Container(
              color: GrayscaleWhiteColors.white,
              width: Get.width,
              height: Get.height,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text("No updates from your community yet"),
                    const Text("Follow some people to see their notes!", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: controller.updates.length,
            itemBuilder: (context, index) {
              return PostCard(
                document: controller.updates[index],
              );
            },
          );
        },
      ),
    );
  }
}
