import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:glassmorphism/glassmorphism.dart";
import "package:notehub/controller/document_controller.dart";
import "package:notehub/core/config/color.dart";
import "package:notehub/core/config/typography.dart";
import "package:notehub/core/helper/custom_icon.dart";
import "package:notehub/model/document_model.dart";
import "package:notehub/view/document_screen/document.dart";
import "package:notehub/view/profile_screen/profile_user.dart";
import "package:notehub/view/widgets/loader.dart";

class PostCard extends StatelessWidget {
  final DocumentModel document;
  const PostCard({
    super.key,
    required this.document,
  });

  @override
  Widget build(context) {
    return Container(
      width: Get.width,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _renderHeader(),
          GestureDetector(
            onTap: () => Get.to(
              () => Document(document: document),
              transition: Transition.rightToLeft,
            ),
            child: _renderImage(),
          ),
          _renderFooter(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _renderHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.to(
              () => ProfileUser(username: document.username),
              transition: Transition.rightToLeft,
            ),
            child: Row(
              children: [
                CustomAvatar(
                    path: document.profile, name: document.displayName),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document.displayName,
                        style: AppTypography.subHead1
                            .copyWith(fontWeight: FontWeight.bold)),
                    Text(document.topic,
                        style: AppTypography.body4
                            .copyWith(color: PrimaryColor.shade500)),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          const Icon(Icons.more_vert, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _renderImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            CachedNetworkImage(
              height: 250,
              width: Get.width,
              fit: BoxFit.cover,
              imageUrl: document.icon,
              placeholder: (context, url) => const Loader(),
              errorWidget: (context, url, error) => Container(
                height: 250,
                color: GrayscaleWhiteColors.almostWhite,
                child: const Center(
                    child:
                        Icon(Icons.description, size: 50, color: Colors.grey)),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassmorphicContainer(
                width: Get.width,
                height: 60,
                borderRadius: 0,
                blur: 10,
                alignment: Alignment.bottomCenter,
                border: 0,
                linearGradient: AppGradients.glassGradient,
                borderGradient: AppGradients.glassGradient,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.name,
                          style: AppTypography.subHead2.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (document.isExternal)
                        const Icon(Icons.link_rounded,
                            color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderFooter() {
    return GetBuilder<DocumentController>(
      builder: (controller) => Padding(
        padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
        child: Row(
          children: [
            _interactionItem(
              icon: document.isLiked
                  ? Icons.thumb_up_rounded
                  : Icons.thumb_up_outlined,
              count: document.likes,
              color: document.isLiked ? Colors.blue : Colors.grey,
              onTap: () => controller.toggleLike(document),
            ),
            const SizedBox(width: 16),
            _interactionItem(
              icon: document.isDisliked
                  ? Icons.thumb_down_rounded
                  : Icons.thumb_down_outlined,
              count: document.dislikes,
              color: document.isDisliked ? Colors.orange : Colors.grey,
              onTap: () => controller.toggleDislike(document),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => controller.toggleBookmark(document),
              child: Icon(
                document.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color:
                    document.isBookmarked ? PrimaryColor.shade500 : Colors.grey,
                size: 26,
              ),
            ),
            const Spacer(),
            Text(
              "MU Resources",
              style: AppTypography.body4.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _interactionItem(
      {required IconData icon,
      required int count,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 4),
          Text(count.toString(),
              style: AppTypography.body3
                  .copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
