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
    if (nameEditingController.text.isEmpty || topicEditingController.text.isEmpty) {
      Toasts.showTostWarning(message: "Please fill all required fields");
      return;
    }

    if (isExternalLink.value) {
      if (linkEditingController.text.isEmpty) {
        Toasts.showTostWarning(message: "Please provide a link");
        return;
      }
    } else {
      if (selectedDocument.value == null) {
        Toasts.showTostWarning(message: "Please select a document");
        return;
      }
      if (selectedDocument.value!.size > 10 * 1024 * 1024) {
        Toasts.showTostWarning(message: "Direct upload limit is 10MB. Use a Drive link for larger files.");
        return;
      }
    }

    if (selectedCover.value == null) {
      Toasts.showTostWarning(message: "Please select a cover image");
      return;
    }

    isLoading.value = true;
    try {
      final userId = HiveBoxes.userId;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 1. Compress and Upload Cover
      File coverFile = File(selectedCover.value!.path!);
      File? compressedCover = await ImageHelper.compressImage(coverFile);

      final coverPath = '$userId/covers/${timestamp}_${nameEditingController.text}.jpg';
      await supabase.storage.from('documents').upload(
        coverPath,
        compressedCover ?? coverFile,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      final coverUrl = supabase.storage.from('documents').getPublicUrl(coverPath);

      String docUrl = "";
      String docName = "";

      if (isExternalLink.value) {
        docUrl = linkEditingController.text.trim();
        docName = "External Link";
      } else {
        // 2. Upload Document
        final docFile = File(selectedDocument.value!.path!);
        final docExt = p.extension(docFile.path);
        final docPath = '$userId/docs/${timestamp}_${nameEditingController.text}$docExt';
        await supabase.storage.from('documents').upload(docPath, docFile);
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

      Toasts.showTostSuccess(message: "Document shared successfully!");
      clearForm();
      Get.back();
    } catch (e) {
      print("Upload error: $e");
      Toasts.showTostError(message: "Failed to upload document");
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
