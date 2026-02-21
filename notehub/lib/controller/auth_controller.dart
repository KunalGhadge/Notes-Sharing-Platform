import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/helper/hive_boxes.dart';
import 'package:notehub/layout.dart';
import 'package:notehub/model/user_model.dart';
import 'package:notehub/view/widgets/toasts.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var isRegister = false.obs;

  var emailEditingController = TextEditingController();
  var passwordEditingController = TextEditingController();
  var displayNameController = TextEditingController();
  var instituteController = TextEditingController(text: "Mumbai University");

  bool verifyForm({bool isRegister = false}) {
    if (emailEditingController.text.isEmpty ||
        !emailEditingController.text.contains("@")) {
      Toasts.showTostWarning(message: "Enter a valid email address");
      return false;
    }

    if (passwordEditingController.text.length < 6) {
      Toasts.showTostWarning(message: "Password must be at least 6 characters");
      return false;
    }

    if (isRegister && displayNameController.text.isEmpty) {
      Toasts.showTostWarning(message: "Enter your name");
      return false;
    }

    return true;
  }

  Future<void> loginWithEmail() async {
    if (!verifyForm()) return;

    isLoading.value = true;
    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailEditingController.text.trim(),
        password: passwordEditingController.text.trim(),
      );

      if (response.user != null) {
        await fetchAndStoreProfile(response.user!);
        Get.offAll(() => const Layout());
      }
    } on AuthException catch (error) {
      Toasts.showTostError(message: error.message);
    } catch (error) {
      Toasts.showTostError(message: "An unexpected error occurred");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerWithEmail() async {
    if (!verifyForm(isRegister: true)) return;

    isLoading.value = true;
    try {
      final response = await supabase.auth.signUp(
        email: emailEditingController.text.trim(),
        password: passwordEditingController.text.trim(),
        data: {
          'display_name': displayNameController.text.trim(),
          'institute': instituteController.text.trim(),
        },
        emailRedirectTo: 'io.supabase.flutternotehub://login-callback',
      );

      if (response.user != null) {
        if (response.session != null) {
          await supabase.from('profiles').upsert({
            'id': response.user!.id,
            'username': emailEditingController.text.trim(),
            'display_name': displayNameController.text.trim(),
            'institute': instituteController.text.trim(),
          });

          await fetchAndStoreProfile(response.user!);
          Toasts.showTostSuccess(message: "Registration successful!");
          Get.offAll(() => const Layout());
        } else {
          Toasts.showTostSuccess(
              message: "Please check your email to confirm your account!");
          isRegister.value = false; // Switch back to login for when they return
        }
      }
    } on AuthException catch (error) {
      Toasts.showTostError(message: error.message);
    } catch (error) {
      Toasts.showTostError(message: "Registration failed");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAndStoreProfile(User user, {int retryCount = 0}) async {
    try {
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData == null) {
        if (retryCount > 1) throw Exception("Profile creation failed");

        // Create profile from metadata if it doesn't exist
        final metadata = user.userMetadata ?? {};
        await supabase.from('profiles').upsert({
          'id': user.id,
          'username': user.email ?? "user_${user.id.substring(0, 5)}",
          'display_name': metadata['display_name'] ?? "User",
          'institute': metadata['institute'] ?? "Mumbai University",
        });
        // Retry fetching the newly created profile
        return await fetchAndStoreProfile(user, retryCount: retryCount + 1);
      }

      final counts = await getCounts(user.id);

      var newUser = UserModel(
        id: user.id,
        displayName: profileData['display_name'] ?? "User",
        username: profileData['username'],
        institute: profileData['institute'] ?? "Mumbai University",
        profile: profileData['profile_url'] ?? "NA",
        documents: counts['documents'] ?? 0,
        followers: counts['followers'] ?? 0,
        following: counts['following'] ?? 0,
      );
      await HiveBoxes.setUser(newUser);
    } catch (e) {
      Toasts.showTostError(message: "Failed to load user profile");
    }
  }

  Future<Map<String, int>> getCounts(String userId) async {
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

    return {
      'documents': docsRes.count,
      'followers': followersRes.count,
      'following': followingRes.count,
    };
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    await HiveBoxes.resetUser();
  }
}
