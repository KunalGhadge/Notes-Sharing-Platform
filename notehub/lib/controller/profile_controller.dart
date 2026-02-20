import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/user_model.dart';
import 'package:notehub/view/auth_screen/login.dart';
import 'package:notehub/view/widgets/toasts.dart';

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

      final docsRes = await supabase
          .from('documents')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact);
      final followersRes = await supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId)
          .count(CountOption.exact);
      final followingRes = await supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId)
          .count(CountOption.exact);

      user.value = UserModel(
        id: userId,
        displayName: profileData['display_name'] ?? "User",
        username: profileData['username'],
        institute: profileData['institute'] ?? "Mumbai University",
        profile: profileData['profile_url'] ?? "NA",
        documents: docsRes.count,
        followers: followersRes.count,
        following: followingRes.count,
        academicInterests:
            List<String>.from(profileData['academic_interests'] ?? []),
      );

      if (username == HiveBoxes.username) {
        await HiveBoxes.setUser(user.value);
      }
    } catch (e) { /* silent */ } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({String? name, String? institute, List<String>? interests}) async {
    isLoading.value = true;
    try {
      final userId = HiveBoxes.userId;
      await supabase.from('profiles').update({
        if (name != null) 'display_name': name,
        if (institute != null) 'institute': institute,
        if (interests != null) 'academic_interests': interests,
      }).eq('id', userId);

      fetchUserData(username: HiveBoxes.username);
      Toasts.showTostSuccess(message: "Profile updated successfully");
    } catch (e) {
      Toasts.showTostError(message: "Failed to update profile");
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
