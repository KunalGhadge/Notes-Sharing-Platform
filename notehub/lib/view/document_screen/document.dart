import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/document_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/core/helper/custom_icon.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/document_model.dart';
import 'package:notehub/service/file_download.dart';
import 'package:notehub/view/document_screen/widget/doc_description.dart';
import 'package:notehub/view/document_screen/widget/follow_button.dart';
import 'package:notehub/view/document_screen/widget/comment_section.dart';
import 'package:notehub/view/widgets/primary_button.dart';
import 'package:notehub/view/widgets/secondary_button.dart';
import 'package:notehub/view/widgets/admin_badge.dart';

class Document extends StatefulWidget {
  final DocumentModel document;
  const Document({super.key, required this.document});

  @override
  State<Document> createState() => _DocumentState();
}

class _DocumentState extends State<Document> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Dio dio = Dio();
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        FileDownload.onNotificationClick(response.payload);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: PrimaryColor.shade500),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          shrinkWrap: true,
          children: [
            _renderHeader(),
            const SizedBox(height: 24),
            DocDescription(document: widget.document),
            const SizedBox(height: 32),
            if (widget.document.postType == 'note') ...[
              _renderDownloader(),
              const SizedBox(height: 32),
            ],
            const Divider(),
            const SizedBox(height: 24),
            CommentSection(docId: widget.document.documentId),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _renderHeader() {
    return Row(
      children: [
        CustomAvatar(path: widget.document.profile),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.document.displayName,
                    style: AppTypography.subHead1
                        .copyWith(fontWeight: FontWeight.bold)),
                if (widget.document.isOfficial) // Admins are usually official
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: AdminBadge(fontSize: 8),
                  ),
              ],
            ),
            Text(widget.document.username,
                style: AppTypography.body4.copyWith(color: Colors.grey)),
          ],
        ),
        const Spacer(),
        if (HiveBoxes.userId != "" &&
            HiveBoxes.username != widget.document.username)
          FollowButton(document: widget.document)
        else if (HiveBoxes.username == widget.document.username)
          GetBuilder<DocumentController>(
            builder: (controller) => GestureDetector(
              onTap: () {
                Get.defaultDialog(
                  title: "Delete Document",
                  middleText: "Are you sure you want to delete this resource?",
                  textConfirm: "Delete",
                  textCancel: "Cancel",
                  confirmTextColor: Colors.white,
                  buttonColor: DangerColors.shade500,
                  onConfirm: () {
                    Get.back();
                    controller.deleteDocument(widget.document);
                  },
                );
              },
              child: Icon(Icons.delete_outline_rounded,
                  color: DangerColors.shade500, size: 28),
            ),
          ),
      ],
    );
  }

  Widget _renderDownloader() {
    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            onTap: () {
              Get.find<DocumentController>().openDocument(widget.document);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                widget.document.isExternal
                    ? "Open External Link"
                    : "View Document",
                style: AppTypography.subHead2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        if (!widget.document.isExternal) ...[
          const SizedBox(width: 12),
          SecondaryButton(
            width: 60,
            onTap: () {
              FileDownload.download(
                document: widget.document,
                flutterLocalNotificationsPlugin:
                    flutterLocalNotificationsPlugin,
              );
            },
            child: Icon(Icons.download_rounded, color: PrimaryColor.shade500),
          ),
        ],
      ],
    );
  }
}
