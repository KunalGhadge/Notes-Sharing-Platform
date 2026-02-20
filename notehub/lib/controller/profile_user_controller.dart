import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/model/user_model.dart';
import 'package:notehub/view/widgets/toasts.dart';

class ProfileUserController extends GetxController {
  final supabase = Supabase.instance.client;

  var profileData = UserModel(
    displayName: '',
    username: "",
    institute: "Mumbai University",
    profile: "NA",
    followers: 0,
    following: 0,
    documents: 0,
  ).obs;

  var isLoading = false.obs;

  Future<void> fetchUserData({required String username}) async {
    isLoading.value = true;
    try {
      final profileResponse = await supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .single();

      final userId = profileResponse['id'];
      final currentUserId = HiveBoxes.userId;

      final followResponse = await supabase
          .from('follows')
          .select()
          .match({'follower_id': currentUserId, 'following_id': userId})
          .maybeSingle();

      final isFollowed = followResponse != null;

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

      profileData.value = UserModel(
        id: userId,
        displayName: profileResponse['display_name'] ?? "User",
        username: profileResponse['username'],
        profile: profileResponse['profile_url'] ?? "NA",
        institute: profileResponse['institute'] ?? "Mumbai University",
        followers: followersRes.count,
        following: followingRes.count,
        documents: docsRes.count,
        isFollowedByUser: isFollowed,
      );
    } catch (error) { /* silent */ } finally {
      isLoading.value = false;
    }
  }

  Future<bool> follow({required String username, bool isProfile = true}) async {
    isLoading.value = true;
    try {
      final currentUserId = HiveBoxes.userId;
      final targetUserId = profileData.value.id;

      if (targetUserId == null) return false;

      if (profileData.value.isFollowedByUser) {
        await supabase
            .from('follows')
            .delete()
            .match({'follower_id': currentUserId, 'following_id': targetUserId});
        Toasts.showTostSuccess(message: "Unfollowed $username");
      } else {
        await supabase
            .from('follows')
            .insert({'follower_id': currentUserId, 'following_id': targetUserId});
        Toasts.showTostSuccess(message: "Followed $username");
      }

      if (isProfile) {
        await fetchUserData(username: username);
      }
      return true;
    } catch (e) {
      Toasts.showTostError(message: "Unable to take action");

      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
