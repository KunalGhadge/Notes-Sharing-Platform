import 'package:flutter/material.dart';
import 'package:notehub/core/config/typography.dart';

class AdminBadge extends StatelessWidget {
  final double? fontSize;
  const AdminBadge({super.key, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Premium Gold
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            "ADMIN",
            style: AppTypography.body3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize ?? 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
