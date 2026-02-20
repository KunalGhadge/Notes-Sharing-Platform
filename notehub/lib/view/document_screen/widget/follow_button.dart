import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/profile_user_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/model/document_model.dart';

class FollowButton extends StatefulWidget {
  final DocumentModel document;
  const FollowButton({super.key, required this.document});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  var isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileUserController>();
    return Obx(
      () => SizedBox(
        height: 36,
        child: TextButton(
          onPressed: () async {
            isLoading.value = true;
            bool success = await controller.follow(
              username: widget.document.username,
              isProfile: false,
            );
            if (success) {
              widget.document.isFollowedByUser = !widget.document.isFollowedByUser;
            }
            isLoading.value = false;
          },
          style: TextButton.styleFrom(
            backgroundColor: widget.document.isFollowedByUser
                ? PrimaryColor.shade100
                : PrimaryColor.shade500,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading.value
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.document.isFollowedByUser ? PrimaryColor.shade500 : Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.document.isFollowedByUser ? Icons.check : Icons.add,
                      size: 16,
                      color: widget.document.isFollowedByUser ? PrimaryColor.shade500 : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.document.isFollowedByUser ? "Following" : "Follow",
                      style: AppTypography.body3.copyWith(
                        color: widget.document.isFollowedByUser ? PrimaryColor.shade500 : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
