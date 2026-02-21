import 'package:flutter/material.dart';

import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/auth_controller.dart';
import 'package:notehub/core/helper/custom_icon.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      child: Obx(
        () => Column(
          children: [
            CustomIcon(
              path: controller.isRegister.value
                  ? "assets/icons/user-plus.svg"
                  : "assets/icons/log-in.svg",
              size: 70,
              color: OtherColors.amethystPurple,
            ),
            const SizedBox(height: 12),
            Text(
              controller.isRegister.value ? "Register" : "Login",
              style: AppTypography.heading4,
            ),
            const SizedBox(height: 8),
            Text(
              controller.isRegister.value
                  ? "Join our student community!"
                  : "Good to Have you Back!",
              style: AppTypography.subHead1.copyWith(
                color: GrayscaleGrayColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
