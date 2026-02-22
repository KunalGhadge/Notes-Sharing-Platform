import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notehub/controller/home_controller.dart';
import 'package:notehub/view/home_screen/widget/home_header.dart';
import 'package:notehub/view/widgets/document_card.dart';

class OfficialScreen extends StatelessWidget {
  const OfficialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            const SafeArea(child: SizedBox(height: 10)),
            const HomeHeader(), // Reusing header for consistency
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                final officialDocs = homeController.officialUpdates;

                if (officialDocs.isEmpty) {
                  return const Center(
                    child: Text("No official updates yet."),
                  );
                }

                return ListView.builder(
                  itemCount: officialDocs.length,
                  itemBuilder: (context, index) {
                    return DocumentCard(
                      document: officialDocs[index],
                      actionType: ActionType.more,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
