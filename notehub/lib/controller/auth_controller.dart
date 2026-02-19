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
      );

      if (response.user != null) {
        await supabase.from('profiles').upsert({
          'id': response.user!.id,
          'username': emailEditingController.text.trim(),
          'display_name': displayNameController.text.trim(),
          'institute': instituteController.text.trim(),
        });

        await fetchAndStoreProfile(response.user!);
        Toasts.showTostSuccess(message: "Registration successful!");
        Get.offAll(() => const Layout());
      }
    } on AuthException catch (error) {
      Toasts.showTostError(message: error.message);
    } catch (error) {
      Toasts.showTostError(message: "Registration failed");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAndStoreProfile(User user) async {
    final profileData = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

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
  }

  Future<Map<String, int>> getCounts(String userId) async {
    final docs = await supabase.from('documents').select('id').eq('user_id', userId);
    final followers = await supabase.from('follows').select('follower_id').eq('following_id', userId);
    final following = await supabase.from('follows').select('following_id').eq('follower_id', userId);

    return {
      'documents': (docs as List).length,
      'followers': (followers as List).length,
      'following': (following as List).length,
    };
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    await HiveBoxes.resetUser();
  }
}
