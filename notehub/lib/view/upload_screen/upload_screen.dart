import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/upload_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/view/upload_screen/widget/upload_form.dart';
import 'package:notehub/view/widgets/loader.dart';
import 'package:notehub/view/widgets/primary_button.dart';
import 'package:notehub/view/widgets/secondary_button.dart';
import 'package:notehub/view/widgets/toasts.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(UploadController());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: PrimaryColor.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 80,
                      color: PrimaryColor.shade500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Share Resources", style: AppTypography.heading6),
                  Text(
                    "Contribute to Mumbai University Community",
                    style: AppTypography.body3.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  const UploadForm(),
                  const SizedBox(height: 32),
                  const UploadFooter(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Obx(
              () => Get.find<UploadController>().isLoading.value
                  ? Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.1),
                        child: const Center(child: Loader()),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadFooter extends StatelessWidget {
  const UploadFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            onTap: () {
              Get.find<UploadController>().uploadDocument();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "Upload",
                style: AppTypography.subHead2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SecondaryButton(
          onTap: () {
            Get.find<UploadController>().clearForm();
            Toasts.showTostSuccess(message: "Form cleared");
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              "Clear",
              style: AppTypography.subHead2.copyWith(
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
