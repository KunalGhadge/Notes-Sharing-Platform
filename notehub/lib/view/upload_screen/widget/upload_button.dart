import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/upload_controller.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/view/widgets/primary_button.dart';

class UploadButton extends StatelessWidget {
  final String text;
  final String state;
  const UploadButton({super.key, required this.text, required this.state});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      width: 100,
      onTap: () => Get.find<UploadController>().pickFile(state),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            text,
            style: AppTypography.body2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
