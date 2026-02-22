import "dart:io";

import "package:dio/dio.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:get/get.dart";
import "package:notehub/controller/download_controller.dart";
import "package:notehub/core/helper/hive_boxes.dart";
import "package:notehub/model/document_model.dart";
import "package:notehub/view/widgets/toasts.dart";
import "package:open_file/open_file.dart";
import "package:path_provider/path_provider.dart";

final dio = Dio();

class FileDownload {
  static void download({
    required DocumentModel document,
    FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin,
  }) async {
    if (document.document == null) {
      Toasts.showTostError(message: "No document attached to this post");
      return;
    }
    var downloadDir = await getApplicationDocumentsDirectory();
    var downloadUri = Uri.parse(document.document!);

    String savePath =
        "${downloadDir.path}/${document.documentName ?? 'document'}";
    if (await ifFileExists(savePath)) {
      Toasts.showTostWarning(message: "Already downloaded: ${document.name}");
      return;
    }

    var saveFile = File(savePath);

    await dio.downloadUri(
      downloadUri,
      saveFile.path,
      onReceiveProgress: (received, total) {
        Get.find<DownloadController>().downloadProgress.value =
            received / (total == -1 ? 1 : total);
        if (total != -1) {
          int progress = ((received / total) * 100).toInt();
          if (flutterLocalNotificationsPlugin != null) {
            _showProgressNotification(
                progress, flutterLocalNotificationsPlugin);
          }
        }
      },
    );

    // Save to Hive for tracking
    await HiveBoxes.addDownload(document.toJson());

    if (flutterLocalNotificationsPlugin != null) {
      _showCompleteNotification(flutterLocalNotificationsPlugin, savePath);
    }
    Toasts.showTostSuccess(message: "Downloaded: ${document.name}");
  }

  static Future<void> _showProgressNotification(int progress,
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Download Progress',
      importance: Importance.high,
      priority: Priority.high,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Downloading',
      body: '$progress%',
      notificationDetails: notificationDetails,
    );
  }

  static Future<void> _showCompleteNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    String savePath,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Download Complete',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Download Complete',
      body: 'The file has been downloaded successfully',
      notificationDetails: notificationDetails,
      payload: savePath,
    );
  }

  static void onNotificationClick(String? filePath) {
    if (filePath != null) {
      OpenFile.open(filePath);
    }
  }

  static Future<bool> ifFileExists(String path) async {
    var file = File(path);
    if (await file.exists()) {
      return true;
    }

    return false;
  }
}
