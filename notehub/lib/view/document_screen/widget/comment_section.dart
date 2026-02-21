import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/comment_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/core/meta/app_meta.dart';
import 'package:intl/intl.dart';

class CommentSection extends StatefulWidget {
  final String docId;
  const CommentSection({super.key, required this.docId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final controller = Get.put(CommentController());
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.fetchComments(widget.docId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Comments", style: AppTypography.subHead1.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: "Add a comment...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                controller.postComment(widget.docId, textController.text);
                textController.clear();
                FocusScope.of(context).unfocus();
              },
              icon: Icon(Icons.send_rounded, color: PrimaryColor.shade500),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Obx(() {
          if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
          if (controller.comments.isEmpty) return const Text("No comments yet. Be the first to start the discussion!", style: TextStyle(color: Colors.grey));

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.comments.length,
            itemBuilder: (context, index) {
              final comment = controller.comments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(
                        comment.profileUrl == "NA"
                        ? "${AppMetaData.avatarUrl}&name=${comment.displayName}"
                        : comment.profileUrl
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  textController.text = "@${comment.displayName} ";
                                  FocusScope.of(context).requestFocus(FocusNode());
                                },
                                child: Text(comment.displayName, style: AppTypography.body3.copyWith(fontWeight: FontWeight.bold, color: PrimaryColor.shade500)),
                              ),
                              Text(DateFormat.yMMMd().format(comment.createdAt), style: AppTypography.body4.copyWith(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(comment.content, style: AppTypography.body2),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
