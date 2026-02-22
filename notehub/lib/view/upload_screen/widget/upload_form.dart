import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:notehub/controller/upload_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/view/upload_screen/widget/upload_button.dart';
import 'package:notehub/view/widgets/upload_text_field.dart';

import 'package:notehub/core/helper/hive_boxes.dart';

class UploadForm extends StatelessWidget {
  const UploadForm({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<UploadController>(builder: (controller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _renderPostTypeToggle(controller),
          const SizedBox(height: 24),
          if (controller.postType.value == 'note') ...[
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
          ],
          _renderUploadSection(
            title: "Cover Image",
            file: controller.selectedCover.value,
            state: "cover",
            icon: Icons.image_outlined,
          ),
          const SizedBox(height: 32),
          if (HiveBoxes.userBox.get('data')?.isAdmin ?? false) ...[
            _renderAdminToggles(controller),
            const SizedBox(height: 24),
          ],
          UploadTextField(
            text: controller.postType.value == 'tweet'
                ? "Post Title"
                : "Document Name",
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

  Widget _renderPostTypeToggle(UploadController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton(
              text: "Note / Resource",
              isSelected: controller.postType.value == 'note',
              onTap: () => controller.postType.value = 'note',
            ),
          ),
          Expanded(
            child: _toggleButton(
              text: "Short Update (Tweet)",
              isSelected: controller.postType.value == 'tweet',
              onTap: () => controller.postType.value = 'tweet',
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderAdminToggles(UploadController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded,
                  color: Color(0xFFB8860B), size: 20),
              const SizedBox(width: 8),
              Text(
                "Mark as Official Content",
                style: AppTypography.body3.copyWith(
                  color: const Color(0xFFB8860B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Switch(
            value: controller.isOfficial.value,
            onChanged: (v) => controller.isOfficial.value = v,
            activeColor: const Color(0xFFB8860B),
          ),
        ],
      ),
    );
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

  Widget _toggleButton(
      {required String text,
      required bool isSelected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4)
                ]
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
        Text(title,
            style:
                AppTypography.subHead1.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: PrimaryColor.shade100.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PrimaryColor.shade200),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: file != null ? PrimaryColor.shade500 : Colors.grey),
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
              UploadButton(
                  text: file == null ? "Select" : "Change", state: state),
            ],
          ),
        )
      ],
    );
  }
}
