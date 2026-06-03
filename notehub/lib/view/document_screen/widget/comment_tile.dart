import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/comment_controller.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/core/meta/app_meta.dart';
import 'package:intl/intl.dart';
import 'package:notehub/view/widgets/admin_badge.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final List<CommentModel> allComments;
  final Function(CommentModel) onReply;
  final int depth;

  const CommentTile({
    super.key,
    required this.comment,
    required this.allComments,
    required this.onReply,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final replies = allComments.where((c) => c.parentId == comment.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 20.0, bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: comment.isAdmin
                  ? const Color(0xFFFFD700).withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: comment.isAdmin
                  ? Border.all(color: const Color(0xFFFFD700), width: 1)
                  : Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(comment.profileUrl == "NA"
                      ? "${AppMetaData.avatarUrl}&name=${comment.displayName}"
                      : comment.profileUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.displayName,
                            style: AppTypography.body3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: comment.isAdmin
                                    ? const Color(0xFFB8860B)
                                    : PrimaryColor.shade500),
                          ),
                          if (comment.isAdmin)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: AdminBadge(fontSize: 7),
                            ),
                          const Spacer(),
                          Text(
                            DateFormat.yMMMd().format(comment.createdAt),
                            style: AppTypography.body4
                                .copyWith(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(comment.content, style: AppTypography.body2),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => onReply(comment),
                            child: Text(
                              "Reply",
                              style: AppTypography.body3.copyWith(
                                color: PrimaryColor.shade500,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (comment.displayName == HiveBoxes.username ||
                              (HiveBoxes.userBox.get('data')?.isAdmin ??
                                  false)) ...[
                            const SizedBox(width: 16),
                            GetBuilder<CommentController>(
                              builder: (controller) => GestureDetector(
                                onTap: () {
                                  Get.defaultDialog(
                                    title: "Delete Comment",
                                    middleText:
                                        "Permanently remove this comment?",
                                    textConfirm: "Delete",
                                    textCancel: "Cancel",
                                    confirmTextColor: Colors.white,
                                    buttonColor: DangerColors.shade500,
                                    onConfirm: () {
                                      Get.back();
                                      controller.deleteComment(comment.id);
                                    },
                                  );
                                },
                                child: Text(
                                  "Delete",
                                  style: AppTypography.body3.copyWith(
                                    color: DangerColors.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (replies.isNotEmpty)
          ...replies.map((reply) => CommentTile(
                comment: reply,
                allComments: allComments,
                onReply: onReply,
                depth: depth + 1,
              )),
      ],
    );
  }
}
