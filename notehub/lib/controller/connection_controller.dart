import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/mini_user_model.dart';
import 'package:notehub/view/connection_screen/connection.dart';
import 'package:notehub/view/widgets/toasts.dart';

class ConnectionController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var usersData = <MiniUserModel>[].obs;

  Future<void> fetchConnection({required ConnectionType type}) async {
    isLoading.value = true;
    try {
      final currentUserId = HiveBoxes.userId;
      late final dynamic response;

      if (type == ConnectionType.followers) {
        response = await supabase
            .from('follows')
            .select('profiles:follower_id (*)')
            .eq('following_id', currentUserId);
      } else {
        response = await supabase
            .from('follows')
            .select('profiles:following_id (*)')
            .eq('follower_id', currentUserId);
      }

      usersData.clear();
      for (var item in response) {
        final profile = item['profiles'];
        usersData.add(MiniUserModel(
          displayName: profile['display_name'] ?? "User",
          username: profile['username'],
          profile: profile['profile_url'] ?? "NA",
          isFollowedByUser: type == ConnectionType.following,
        ));
      }
    } catch (e) {
      print("Error fetching connections: $e");
      Toasts.showTostError(message: "Error fetching ${type.name}");
    } finally {
      isLoading.value = false;
    }
  }
}
