import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notehub/controller/document_controller.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/service/file_download.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/core/helper/custom_icon.dart';

import 'package:notehub/model/document_model.dart';
import 'package:notehub/view/document_screen/document.dart';
import 'package:notehub/view/widgets/loader.dart';

enum ActionType { edit, more }

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onTap;
  final VoidCallback? action;
  final Function? imageOnTap;
  final ActionType actionType;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.action,
    required this.actionType,
    this.imageOnTap,
  });

  void _showImage() {
    Get.dialog(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.close, color: DangerColors.shade500),
            ),
          ),
          document.icon == ""
              ? const CustomIcon(path: "assets/icons/files.svg")
              : Image.network(
                  document.icon,
                  fit: BoxFit.contain,
                  width: Get.width,
                  height: Get.height / 1.5,
                ),
        ],
      ),
      transitionDuration: Duration.zero,
      transitionCurve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DocumentController>(
        init: DocumentController(),
        builder: (controller) {
          final isTweet = document.postType == 'tweet';

          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: GrayscaleWhiteColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: GrayscaleWhiteColors.almostWhite,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]),
                child: InkWell(
                  onTap: () {
                    Get.to(
                      () => Document(document: document),
                      transition: Transition.rightToLeft,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isTweet)
                              GestureDetector(
                                onTap: () {
                                  if (document.icon != "") {
                                    _showImage();
                                  }
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: GrayscaleWhiteColors.almostWhite,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: document.icon == ""
                                      ? const Center(
                                          child: CustomIcon(
                                              path: "assets/icons/files.svg",
                                              size: 24))
                                      : Image.network(
                                          document.icon,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          document.name,
                                          style: AppTypography.subHead1
                                              .copyWith(height: 1.2),
                                        ),
                                      ),
                                      if (document.isOfficial)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: PrimaryColor.shade500
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: PrimaryColor.shade500,
                                                width: 0.5),
                                          ),
                                          child: Text(
                                            "OFFICIAL",
                                            style: AppTypography.body3.copyWith(
                                              color: PrimaryColor.shade500,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 8,
                                            ),
                                          ),
                                        ),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        onSelected: (value) async {
                                          if (value == 'download') {
                                            FileDownload.download(
                                              document: document,
                                              flutterLocalNotificationsPlugin:
                                                  FlutterLocalNotificationsPlugin(),
                                            );
                                          } else if (value == 'delete') {
                                            Get.defaultDialog(
                                              title: "Delete Content",
                                              middleText:
                                                  "Are you sure you want to delete this post? This action cannot be undone.",
                                              textConfirm: "Delete",
                                              textCancel: "Cancel",
                                              confirmTextColor: Colors.white,
                                              buttonColor:
                                                  DangerColors.shade500,
                                              onConfirm: () {
                                                Get.back();
                                                controller
                                                    .deleteDocument(document);
                                              },
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (document.postType == 'note')
                                            const PopupMenuItem(
                                              value: 'download',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.download_rounded,
                                                      size: 20),
                                                  SizedBox(width: 8),
                                                  Text("Download"),
                                                ],
                                              ),
                                            ),
                                          if (document.username ==
                                              HiveBoxes.username)
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      color:
                                                          DangerColors.shade500,
                                                      size: 20),
                                                  SizedBox(width: 8),
                                                  Text("Delete",
                                                      style: TextStyle(
                                                          color: DangerColors
                                                              .shade500)),
                                                ],
                                              ),
                                            ),
                                        ],
                                        icon: const Icon(Icons.more_vert,
                                            size: 20, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  if (isTweet && document.description != "")
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        document.description,
                                        style: AppTypography.body3.copyWith(
                                          color: GrayscaleGrayColors.mediumGray,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isTweet)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              document.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body3.copyWith(
                                color: GrayscaleGrayColors.mediumGray,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        DocumentFooter(
                          topic: document.topic,
                          likes: document.likes,
                          isLiked: document.isLiked,
                          dateOfUpload: document.dateOfUpload,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (controller.isLoading.value)
                const Positioned.fill(
                  child: Loader(),
                ),
            ],
          );
        });
  }
}

class DocumentFooter extends StatelessWidget {
  final String topic;
  final int likes;
  final bool isLiked;
  final DateTime dateOfUpload;
  const DocumentFooter(
      {super.key,
      required this.topic,
      required this.likes,
      required this.isLiked,
      required this.dateOfUpload});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          topic,
          style: AppTypography.body3.copyWith(
            color: GrayscaleGrayColors.lightGray,
          ),
        ),
        LikesWithHeart(likes: likes, isLiked: isLiked),
        Text(
          DateFormat("d/M/yyyy").format(dateOfUpload),
          style: AppTypography.body3.copyWith(
            color: GrayscaleGrayColors.lightGray,
          ),
        ),
      ],
    );
  }
}

class LikesWithHeart extends StatefulWidget {
  final int likes;
  final bool isLiked;
  const LikesWithHeart({super.key, required this.likes, required this.isLiked});

  @override
  State<LikesWithHeart> createState() => _LikesWithHeartState();
}

class _LikesWithHeartState extends State<LikesWithHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(LikesWithHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          widget.likes.toString(),
          style: AppTypography.body3.copyWith(
            color: GrayscaleGrayColors.lightGray,
          ),
        ),
        const SizedBox(width: 4),
        ScaleTransition(
          scale: _scaleAnimation,
          child: CustomIcon(
            path: "assets/icons/heart-solid.svg",
            size: AppTypography.body3.fontSize,
            color: widget.isLiked ? Colors.red[400] : Colors.grey[300],
          ),
        ),
      ],
    );
  }
}
