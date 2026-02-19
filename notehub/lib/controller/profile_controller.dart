import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/user_model.dart';
import 'package:notehub/view/auth_screen/login.dart';

class ProfileController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var user = UserModel(
    displayName: "",
    username: "",
    institute: "Mumbai University",
    profile: "NA",
  ).obs;

  Future<void> fetchUserData({required String username}) async {
    isLoading.value = true;
    try {
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .single();

      final userId = profileData['id'];

      final docs = await supabase.from('documents').select('id').eq('user_id', userId);
      final followers = await supabase.from('follows').select('follower_id').eq('following_id', userId);
      final following = await supabase.from('follows').select('following_id').eq('follower_id', userId);

      user.value = UserModel(
        id: userId,
        displayName: profileData['display_name'] ?? "User",
        username: profileData['username'],
        institute: profileData['institute'] ?? "Mumbai University",
        profile: profileData['profile_url'] ?? "NA",
        documents: (docs as List).length,
        followers: (followers as List).length,
        following: (following as List).length,
      );

      if (username == HiveBoxes.username) {
        await HiveBoxes.setUser(user.value);
      }
    } catch (e) {
      print("Error fetching profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    await supabase.auth.signOut();
    await HiveBoxes.resetUser();
    Get.offAll(() => const Login());
  }
}
