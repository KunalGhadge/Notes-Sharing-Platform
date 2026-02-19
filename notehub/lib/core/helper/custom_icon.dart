import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:notehub/core/meta/app_meta.dart';

class CustomIcon extends StatelessWidget {
  final String path;
  final double? size;
  final Color? color;

  const CustomIcon({super.key, required this.path, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      color: color,
      height: size,
      width: size,
      fit: BoxFit.contain,
    );
  }
}

class CustomAvatar extends StatelessWidget {
  final String path;
  final String? name;
  final double? radius;
  const CustomAvatar({super.key, required this.path, this.name, this.radius});

  @override
  Widget build(BuildContext context) {
    String finalUrl = path;
    if (path == "" || path == "NA") {
      finalUrl = "${AppMetaData.avatar_url}&name=${name ?? 'User'}";
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(finalUrl),
      backgroundColor: Colors.grey[200],
    );
  }
}
