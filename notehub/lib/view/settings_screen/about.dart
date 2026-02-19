import 'package:flutter/material.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/core/config/typography.dart';
import 'package:notehub/core/meta/app_meta.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppGradients.premiumGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              AppMetaData.appName,
              style: AppTypography.heading4.copyWith(color: PrimaryColor.shade500),
            ),
            const SizedBox(height: 12),
            Text(
              "Mumbai University Student Community",
              style: AppTypography.subHead1.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildSection(
              title: "Our Vision",
              content: "A dedicated community where students and their seniors guide each other by providing quality notes, Previous Year Questions (PYQs), and Important Questions (IMPs).",
              icon: Icons.visibility_rounded,
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "Developers",
              content: "Kunal\nSharonRaj",
              icon: Icons.code_rounded,
            ),
            const SizedBox(height: 40),
            Text(
              "Version 1.0.0",
              style: AppTypography.body4.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PrimaryColor.shade500),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.subHead1.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(content, style: AppTypography.body2.copyWith(color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
