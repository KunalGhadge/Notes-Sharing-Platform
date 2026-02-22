import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/comment_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/view/document_screen/widget/comment_tile.dart';

class CommentSection extends StatefulWidget {
  final String docId;
  const CommentSection({super.key, required this.docId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final controller = Get.put(CommentController());
  final textController = TextEditingController();
  final replyTo = Rxn<CommentModel>();

  @override
  Widget build(BuildContext context) {
    controller.fetchComments(widget.docId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Comments",
            style:
                AppTypography.subHead1.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Obx(() {
          if (replyTo.value != null) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: PrimaryColor.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Replying to ${replyTo.value!.displayName}",
                      style: AppTypography.body3
                          .copyWith(color: PrimaryColor.shade500),
                    ),
                  ),
                  IconButton(
                    onPressed: () => replyTo.value = null,
                    icon: const Icon(Icons.close, size: 18),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: "Add a comment...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                controller.postComment(
                  widget.docId,
                  textController.text,
                  parentId: replyTo.value?.id,
                );
                textController.clear();
                replyTo.value = null;
                FocusScope.of(context).unfocus();
              },
              icon: Icon(Icons.send_rounded, color: PrimaryColor.shade500),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Obx(() {
          if (controller.isLoading.value)
            return const Center(child: CircularProgressIndicator());
          if (controller.comments.isEmpty)
            return const Text(
                "No comments yet. Be the first to start the discussion!",
                style: TextStyle(color: Colors.grey));

          final rootComments =
              controller.comments.where((c) => c.parentId == null).toList();

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rootComments.length,
            itemBuilder: (context, index) {
              return CommentTile(
                comment: rootComments[index],
                allComments: controller.comments,
                onReply: (c) {
                  replyTo.value = c;
                },
              );
            },
          );
        }),
      ],
    );
  }
}
