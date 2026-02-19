import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/auth_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/core/helper/custom_icon.dart';
import 'package:notehub/view/auth_screen/widget/login_fields.dart';
import 'package:notehub/view/widgets/primary_button.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Obx(
      () => Column(
        children: [
          if (controller.isRegister.value) ...[
            PrimaryField(
              text: "Full Name",
              leadingIcon: const Icon(Icons.person_outline),
              controller: controller.displayNameController,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),
            PrimaryField(
              text: "Institute",
              leadingIcon: const Icon(Icons.account_balance_outlined),
              controller: controller.instituteController,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
          ],
          PrimaryField(
            text: "Email",
            leadingIcon: const CustomIcon(path: "assets/icons/mail.svg"),
            controller: controller.emailEditingController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          PrimaryField(
            text: "Password",
            obscureText: true,
            leadingIcon: const CustomIcon(path: "assets/icons/lock.svg"),
            controller: controller.passwordEditingController,
            keyboardType: TextInputType.visiblePassword,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            width: double.infinity,
            onTap: controller.isRegister.value
                ? controller.registerWithEmail
                : controller.loginWithEmail,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                controller.isRegister.value ? "Create Account" : "Login",
                style: AppTypography.heading6.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Social Login (Commented out for production as requested)
          /*
          Row(
            children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("OR")),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          _socialButton(icon: Icons.g_mobiledata_rounded, text: "Continue with Google"),
          */
          TextButton(
            onPressed: () => controller.isRegister.toggle(),
            child: Text(
              controller.isRegister.value
                  ? "Already have an account? Login"
                  : "New student? Register for MU Community",
              style: AppTypography.body2.copyWith(color: PrimaryColor.shade500),
            ),
          ),
        ],
      ),
    );
  }

  /*
  Widget _socialButton({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 8),
          Text(text, style: AppTypography.subHead2),
        ],
      ),
    );
  }
  */
}
