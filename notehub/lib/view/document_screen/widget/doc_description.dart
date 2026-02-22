import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/document_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/model/document_model.dart';
import 'package:notehub/view/document_screen/widget/icon_viewer.dart';

class DocDescription extends StatelessWidget {
  final DocumentModel document;
  const DocDescription({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(document.name,
            style:
                AppTypography.heading6.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(document.topic,
            style:
                AppTypography.subHead2.copyWith(color: PrimaryColor.shade500)),
        const SizedBox(height: 16),
        _renderDescription(),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Get.to(
            () => IconViewer(
              document: document,
            ),
          ),
          child: Hero(
            tag: "IconViewer: ${document.icon}",
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: document.icon,
                height: 300,
                width: Get.width,
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child:
                      const Icon(Icons.image_not_supported_outlined, size: 50),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _renderFooter(),
      ],
    );
  }

  Widget _renderDescription() {
    return Text(
      document.description,
      style: AppTypography.body1.copyWith(color: Colors.grey[800]),
    );
  }

  Widget _renderFooter() {
    return GetBuilder<DocumentController>(
      builder: (controller) => Row(
        children: [
          _interactionButton(
            icon: document.isLiked
                ? Icons.thumb_up_rounded
                : Icons.thumb_up_outlined,
            count: document.likes,
            color: document.isLiked ? Colors.blue : Colors.grey,
            onTap: () => controller.toggleLike(document),
          ),
          const SizedBox(width: 16),
          _interactionButton(
            icon: document.isDisliked
                ? Icons.thumb_down_rounded
                : Icons.thumb_down_outlined,
            count: document.dislikes,
            color: document.isDisliked ? Colors.orange : Colors.grey,
            onTap: () => controller.toggleDislike(document),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => controller.toggleBookmark(document),
            child: Icon(
              document.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color:
                  document.isBookmarked ? PrimaryColor.shade500 : Colors.grey,
              size: 28,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: PrimaryColor.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Mumbai University",
              style: AppTypography.body4.copyWith(color: PrimaryColor.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _interactionButton(
      {required IconData icon,
      required int count,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 6),
          Text(count.toString(),
              style: AppTypography.body2
                  .copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
