import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:notehub/controller/upload_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/view/upload_screen/widget/upload_button.dart';
import 'package:notehub/view/widgets/upload_text_field.dart';

class UploadForm extends StatelessWidget {
  const UploadForm({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<UploadController>(builder: (controller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _renderTypeToggle(controller),
          const SizedBox(height: 24),
          if (controller.isExternalLink.value)
            UploadTextField(
              text: "External Link (Google Drive, Mega, etc.)",
              controller: controller.linkEditingController,
            )
          else
            _renderUploadSection(
              title: "Document (PDF/Images)",
              file: controller.selectedDocument.value,
              state: "document",
              icon: Icons.description_outlined,
            ),
          const SizedBox(height: 20),
          _renderUploadSection(
            title: "Cover Image",
            file: controller.selectedCover.value,
            state: "cover",
            icon: Icons.image_outlined,
          ),
          const SizedBox(height: 32),
          UploadTextField(
            text: "Document Name",
            controller: controller.nameEditingController,
          ),
          const SizedBox(height: 16),
          UploadTextField(
            text: "Subject / Topic",
            controller: controller.topicEditingController,
          ),
          const SizedBox(height: 16),
          UploadTextArea(
            text: "Description (Optional)",
            controller: controller.descriptionEditingController,
          ),
        ],
      );
    });
  }

  Widget _renderTypeToggle(UploadController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton(
              text: "Direct Upload",
              isSelected: !controller.isExternalLink.value,
              onTap: () => controller.isExternalLink.value = false,
            ),
          ),
          Expanded(
            child: _toggleButton(
              text: "External Link",
              isSelected: controller.isExternalLink.value,
              onTap: () => controller.isExternalLink.value = true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({required String text, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
              : [],
        ),
        child: Center(
          child: Text(
            text,
            style: AppTypography.body3.copyWith(
              color: isSelected ? PrimaryColor.shade500 : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderUploadSection({
    required String title,
    required dynamic file,
    required String state,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.subHead1.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: PrimaryColor.shade100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PrimaryColor.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, color: file != null ? PrimaryColor.shade500 : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: file != null ? () => OpenFile.open(file.path) : null,
                  child: Text(
                    file != null ? file.name : "No file selected",
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body2.copyWith(
                      color: file != null ? PrimaryColor.shade500 : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              UploadButton(text: file == null ? "Select" : "Change", state: state),
            ],
          ),
        )
      ],
    );
  }
}
