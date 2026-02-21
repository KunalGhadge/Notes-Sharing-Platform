import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/showcase_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/document_model.dart';
import 'package:notehub/view/widgets/document_card.dart';
import 'package:shimmer/shimmer.dart';

class PostsRenderer extends StatelessWidget {
  final List<DocumentModel> posts;
  final String usernameTag;
  const PostsRenderer(
      {super.key, required this.posts, required this.usernameTag});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShowcaseController>(tag: usernameTag);
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          margin: const EdgeInsets.only(top: 15),
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: GrayscaleWhiteColors.almostWhite,
                highlightColor: GrayscaleWhiteColors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  height: 100,
                  width: Get.width,
                ),
              );
            },
          ),
        );
      }
      if (posts.isEmpty) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Center(child: Text("No Documents to Display")),
          ],
        );
      } else {
          return Container(
            margin: const EdgeInsets.only(top: 15),
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return DocumentCard(
                  document: posts[index],
                  actionType: posts[index].username == HiveBoxes.username
                      ? ActionType.edit
                      : ActionType.more,
                );
              },
            ),
          );
        }
      },
    );
  }
}
