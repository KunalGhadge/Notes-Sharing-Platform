import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/core/helper/image_helper.dart';
import 'package:notehub/view/widgets/toasts.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

class UploadController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var isExternalLink = false.obs;

  var nameEditingController = TextEditingController();
  var topicEditingController = TextEditingController();
  var descriptionEditingController = TextEditingController();
  var linkEditingController = TextEditingController();

  var selectedDocument = Rxn<PlatformFile>();
  var selectedCover = Rxn<PlatformFile>();

  Future<void> pickFile(String state) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: state == "cover" ? FileType.image : FileType.any,
    );

    if (result != null) {
      if (state == "cover") {
        selectedCover.value = result.files.first;
      } else {
        selectedDocument.value = result.files.first;
      }
    }
  }

  Future<void> uploadDocument() async {
    if (nameEditingController.text.isEmpty ||
        topicEditingController.text.isEmpty) {
      Toasts.showTostWarning(
          message:
              "All major fields are required for quality community notes.");
      return;
    }

    if (isExternalLink.value) {
      if (linkEditingController.text.isEmpty) {
        Toasts.showTostWarning(
            message: "Please provide a valid external resource link.");
        return;
      }
    } else {
      if (selectedDocument.value == null) {
        Toasts.showTostWarning(message: "Please select a document to upload.");
        return;
      }
      // 10MB Limit Check
      if (selectedDocument.value!.size > 10 * 1024 * 1024) {
        Toasts.showTostWarning(
            message:
                "This file exceeds our 10MB direct upload limit. To help us stay free, please use a Google Drive or Mega link instead.");
        return;
      }
    }

    if (selectedCover.value == null) {
      Toasts.showTostWarning(
          message: "A cover image helps others find your notes easily.");
      return;
    }

    isLoading.value = true;
    try {
      final session = supabase.auth.currentSession;
      if (session == null || session.isExpired) {
        Toasts.showTostError(
            message:
                "Your session has expired. Please sign in again to upload notes.");
        return;
      }

      final userId = HiveBoxes.userId.isNotEmpty
          ? HiveBoxes.userId
          : supabase.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        Toasts.showTostError(
            message: "User context not found. Please try logging in again.");
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName =
          nameEditingController.text.replaceAll(RegExp(r'[^\w\s\-]'), '_');

      // 1. Compress and Upload Cover
      File coverFile = File(selectedCover.value!.path!);
      File? compressedCover = await ImageHelper.compressImage(coverFile);

      final coverPath = '$userId/covers/${timestamp}_$sanitizedName.jpg';

      try {
        await supabase.storage.from('documents').upload(
              coverPath,
              compressedCover ?? coverFile,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      } on StorageException catch (e) {
        if (e.statusCode == '413') {
          Toasts.showTostError(
              message:
                  "The cover image is too large. Please use a smaller file.");
        } else {
          Toasts.showTostError(message: "Cover upload failed: ${e.message}");
        }
        return;
      } catch (e) {
        Toasts.showTostError(
            message: "An unexpected error occurred during cover upload: $e");
        return;
      }

      final coverUrl =
          supabase.storage.from('documents').getPublicUrl(coverPath);

      String docUrl = "";
      String docName = "";

      if (isExternalLink.value) {
        docUrl = linkEditingController.text.trim();
        docName = "External Resource";
      } else {
        // 2. Upload Document
        final docFile = File(selectedDocument.value!.path!);
        final docExt = p.extension(docFile.path);
        final docPath = '$userId/docs/${timestamp}_$sanitizedName$docExt';

        try {
          await supabase.storage.from('documents').upload(docPath, docFile);
        } on StorageException catch (e) {
          if (e.statusCode == '413') {
            Toasts.showTostError(
                message: "This document is too large. 10MB limit applies.");
          } else {
            Toasts.showTostError(
                message: "Document upload failed: ${e.message}");
          }
          return;
        } catch (e) {
          Toasts.showTostError(
              message:
                  "An unexpected error occurred during document upload: $e");
          return;
        }

        docUrl = supabase.storage.from('documents').getPublicUrl(docPath);
        docName = selectedDocument.value!.name;
      }

      // 3. Save to Database
      await supabase.from('documents').insert({
        'user_id': userId,
        'name': nameEditingController.text.trim(),
        'topic': topicEditingController.text.trim(),
        'description': descriptionEditingController.text.trim(),
        'document_url': docUrl,
        'cover_url': coverUrl,
        'document_name': docName,
        'is_external': isExternalLink.value,
      });

      Toasts.showTostSuccess(
          message: "Your contribution has been shared with the community!");
      clearForm();
      Get.back();
    } on PostgrestException catch (e) {
      Toasts.showTostError(message: "Database error: ${e.message}");
    } catch (e) {
 fix-auth-registration-issue-15629369363913246465
      String msg = "We encountered an issue while saving your notes. Please try again in a moment.";
      if (e is PostgrestException) msg = e.message;
      if (e is StorageException) msg = "Storage Error: ${e.message}";
      Toasts.showTostError(message: msg);

      Toasts.showTostError(message: "An unexpected error occurred: $e");
 main
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    nameEditingController.clear();
    topicEditingController.clear();
    descriptionEditingController.clear();
    linkEditingController.clear();
    selectedDocument.value = null;
    selectedCover.value = null;
  }
}
