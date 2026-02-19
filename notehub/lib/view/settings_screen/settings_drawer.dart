import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:notehub/controller/profile_controller.dart";
import "package:notehub/core/config/color.dart";
import "package:notehub/core/config/typography.dart";
import "package:notehub/view/settings_screen/about.dart";

class SettingsDrawerController extends GetxController {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  openDrawer() {
    scaffoldKey.currentState!.openDrawer();
  }

  closeDrawer() {
    scaffoldKey.currentState!.closeDrawer();
  }
}

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings", style: AppTypography.heading6),
            const SizedBox(height: 32),
            _buildDrawerItem(
              icon: Icons.info_outline_rounded,
              title: "About Serious Study",
              onTap: () => Get.to(() => const AboutPage()),
            ),
            const Spacer(),
            ListTile(
              onTap: () => Get.find<ProfileController>().logout(),
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout_rounded, color: DangerColors.shade500),
              title: Text(
                "Log out",
                style: AppTypography.subHead2.copyWith(color: DangerColors.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: PrimaryColor.shade500),
      title: Text(title, style: AppTypography.subHead2),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
