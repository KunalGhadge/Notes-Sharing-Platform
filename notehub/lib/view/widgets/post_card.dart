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

class PostCard extends StatefulWidget {
  final DocumentModel document;
  const PostCard({
    super.key,
    required this.document,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
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
            color: Colors.black.withOpacity(0.05),
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
              () => Document(document: widget.document),
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

  _renderHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.to(
              () => ProfileUser(username: widget.document.username),
              transition: Transition.rightToLeft,
            ),
            child: Row(
              children: [
                CustomAvatar(path: widget.document.profile),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.document.displayName,
                        style: AppTypography.subHead1.copyWith(fontWeight: FontWeight.bold)),
                    Text(widget.document.topic, style: AppTypography.body4.copyWith(color: PrimaryColor.shade500)),
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

  _renderImage() {
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
              imageUrl: widget.document.icon,
              placeholder: (context, url) => const Loader(),
              errorWidget: (context, url, error) => Container(
                height: 250,
                color: GrayscaleWhiteColors.almostWhite,
                child: const Center(child: Icon(Icons.description, size: 50, color: Colors.grey)),
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
                          widget.document.name,
                          style: AppTypography.subHead2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

  _renderFooter() {
    return GetBuilder<DocumentController>(
      builder: (controller) => Padding(
        padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => controller.toggleLike(widget.document),
              child: Icon(
                widget.document.isLiked ? Icons.favorite : Icons.favorite_border,
                color: widget.document.isLiked ? Colors.red : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 6),
            Text("${widget.document.likes}", style: AppTypography.body1),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => controller.toggleBookmark(widget.document),
              child: Icon(
                widget.document.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: widget.document.isBookmarked ? PrimaryColor.shade500 : Colors.grey,
                size: 28,
              ),
            ),
            const Spacer(),
            Text(
              "MU Notes",
              style: AppTypography.body4.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
