import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/core/meta/app_meta.dart';
import 'package:notehub/view/auth_screen/login.dart';
import 'package:notehub/layout.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  _redirect() async {
    await Future.delayed(const Duration(seconds: 3));
    Get.offAll(() => HiveBoxes.userId.isNotEmpty ? const Layout() : const Login());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppGradients.premiumGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieBuilder.asset(
              "assets/animations/notes.json",
              height: 250,
              width: 250,
            ),
            const SizedBox(height: 20),
            Text(
              AppMetaData.appName,
              style: AppTypography.heading2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Mumbai University Student Community",
              style: AppTypography.subHead1.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
