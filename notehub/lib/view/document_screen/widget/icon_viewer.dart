import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:notehub/core/helper/custom_icon.dart';

import 'package:notehub/service/file_download.dart';

import 'package:notehub/view/widgets/loader.dart';
import 'package:notehub/view/widgets/normal_button.dart';

import 'package:notehub/model/document_model.dart';

class IconViewer extends StatelessWidget {
  final DocumentModel document;
  const IconViewer({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          NormalButton(
            onPressed: () => FileDownload.download(
              document: document,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text("Download"),
                  SizedBox(width: 8),
                  CustomIcon(path: "assets/icons/download.svg"),
                ],
              ),
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Hero(
        tag: "IconViewer: ${document.icon}",
        child: CachedNetworkImage(
          imageUrl: document.icon,
          placeholder: (context, url) => const Loader(),
          fit: BoxFit.fill,
          width: Get.width,
        ),
      ),
    );
  }
}
