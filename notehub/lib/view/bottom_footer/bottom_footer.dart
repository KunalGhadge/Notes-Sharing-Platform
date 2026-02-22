import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/bottom_navigation_controller.dart';
import 'package:notehub/controller/profile_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/helper/custom_icon.dart';

class BottomFooter extends StatelessWidget {
  const BottomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GetX<BottomNavigationController>(
        builder: (controller) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                isSelected: controller.currentPage.value == 0,
                onTap: () => controller.currentPage.value = 0,
              ),
              _buildNavItem(
                icon: Icons.verified_user_rounded, // Official icon
                isSelected: controller.currentPage.value == 1,
                onTap: () => controller.currentPage.value = 1,
              ),
              _buildNavItem(
                icon: Icons.search_rounded,
                isSelected: controller.currentPage.value == 2,
                onTap: () => controller.currentPage.value = 2,
              ),
              _buildNavItem(
                icon: Icons.add_circle_outline_rounded,
                isSelected: controller.currentPage.value == 3,
                onTap: () => controller.currentPage.value = 3,
              ),
              GestureDetector(
                onTap: () => controller.currentPage.value = 4,
                child: Obx(() {
                  final profileController = Get.find<ProfileController>();
                  return Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: controller.currentPage.value == 4
                            ? PrimaryColor.shade500
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CustomAvatar(
                      radius: 14,
                      name: profileController.user.value.displayName,
                      path: profileController.user.value.profile,
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? PrimaryColor.shade500.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: isSelected ? PrimaryColor.shade500 : Colors.grey,
          size: 26,
        ),
      ),
    );
  }
}
