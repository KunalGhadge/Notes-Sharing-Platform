import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import 'package:notehub/controller/search_controller.dart';
import 'package:notehub/core/config/color.dart';
import 'package:notehub/view/widgets/post_card.dart';

class SearchView extends StatelessWidget {
  SearchView({super.key});

  final controller = Get.put(AppSearchController());
  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          onChanged: (val) => controller.searchDocuments(val),
          decoration: const InputDecoration(
            hintText: "Search notes, topics, or subjects...",
            border: InputBorder.none,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () => searchController.clear(), icon: const Icon(Icons.close)),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
              if (controller.results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text("No resources found yet", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: controller.results.length,
                itemBuilder: (context, index) => PostCard(document: controller.results[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final topics = ['All', 'Maths', 'Physics', 'Engineering', 'Coding', 'MU Special'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(topics[index]),
              onPressed: () => controller.searchDocuments(searchController.text, topic: topics[index]),
              backgroundColor: PrimaryColor.shade100,
              labelStyle: TextStyle(color: PrimaryColor.shade900),
            ),
          );
        },
      ),
    );
  }
}
