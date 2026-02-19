import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/profile_controller.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/view/widgets/primary_button.dart';

class EditProfileDialog extends StatelessWidget {
  EditProfileDialog({super.key});

  final controller = Get.find<ProfileController>();
  final nameController = TextEditingController();
  final instController = TextEditingController();
  final interestsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    nameController.text = controller.user.value.displayName;
    instController.text = controller.user.value.institute;
    interestsController.text = controller.user.value.academicInterests.join(", ");

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit Profile", style: AppTypography.heading6),
              const SizedBox(height: 24),
              _textField(label: "Display Name", controller: nameController),
              const SizedBox(height: 16),
              _textField(label: "Institute", controller: instController),
              const SizedBox(height: 16),
              _textField(
                label: "Academic Interests (comma separated)",
                controller: interestsController,
                hint: "e.g. Maths, Physics, Coding",
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                onTap: () {
                  List<String> interests = interestsController.text
                      .split(",")
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  controller.updateProfile(
                    name: nameController.text,
                    institute: instController.text,
                    interests: interests,
                  );
                  Get.back();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({required String label, required TextEditingController controller, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.body4.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
