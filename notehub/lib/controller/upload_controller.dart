import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/view/widgets/toasts.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

class UploadController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;

  var nameEditingController = TextEditingController();
  var topicEditingController = TextEditingController();
  var descriptionEditingController = TextEditingController();

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

    if (selectedDocument.value == null || selectedCover.value == null) {
      Toasts.showTostWarning(message: "Please select both document and cover");
      return;
    }

    isLoading.value = true;
    try {
      final userId = HiveBoxes.userId;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final docFile = File(selectedDocument.value!.path!);
      final coverFile = File(selectedCover.value!.path!);

      final docExt = p.extension(docFile.path);
      final docPath = '$userId/docs/${timestamp}_${nameEditingController.text}$docExt';
      await supabase.storage.from('documents').upload(docPath, docFile);
      final docUrl = supabase.storage.from('documents').getPublicUrl(docPath);

      final coverExt = p.extension(coverFile.path);
      final coverPath = '$userId/covers/${timestamp}_${nameEditingController.text}$coverExt';
      await supabase.storage.from('documents').upload(coverPath, coverFile);
      final coverUrl = supabase.storage.from('documents').getPublicUrl(coverPath);

      await supabase.from('documents').insert({
        'user_id': userId,
        'name': nameEditingController.text.trim(),
        'topic': topicEditingController.text.trim(),
        'description': descriptionEditingController.text.trim(),
        'document_url': docUrl,
        'cover_url': coverUrl,
        'document_name': selectedDocument.value!.name,
      });

      Toasts.showTostSuccess(message: "Document uploaded successfully!");
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
    selectedDocument.value = null;
    selectedCover.value = null;
  }
}
