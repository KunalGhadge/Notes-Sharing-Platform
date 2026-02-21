import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';

class Toasts {
  static void showTostSuccess({required String message}) {
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text("Success", style: AppTypography.subHead1),
      description: RichText(
        text: TextSpan(
          text: message,
          style: AppTypography.body2.copyWith(
            color: GrayscaleBlackColors.black,
          ),
        ),
      ),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      icon: const Icon(Icons.done),
      showIcon: true,
      primaryColor: Colors.green,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  static void showTostError({required String message}) {
    toastification.show(
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text("Error", style: AppTypography.subHead1),
      description: RichText(
        text: TextSpan(
          text: message,
          style: AppTypography.body2.copyWith(
            color: GrayscaleBlackColors.black,
          ),
        ),
      ),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      icon: const Icon(Icons.error),
      showIcon: true,
      primaryColor: Colors.red,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  static void showTostWarning({required String message}) {
    toastification.show(
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text("Warning", style: AppTypography.subHead1),
      description: RichText(
        text: TextSpan(
          text: message,
          style: AppTypography.body2.copyWith(
            color: GrayscaleBlackColors.black,
          ),
        ),
      ),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      icon: const Icon(Icons.warning),
      showIcon: true,
      primaryColor: Colors.red,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
    );
  }
}
