import 'package:hive/hive.dart';
import 'package:notehub/model/user_model.dart';

class HiveBoxes {
  static Box<UserModel> userBox = Hive.box<UserModel>("user");
  static Box downloadsBox = Hive.box("downloads");

  static String get username => HiveBoxes.userBox.containsKey('data')
      ? userBox.get("data")!.username
      : "";

  static String get userId => HiveBoxes.userBox.containsKey('data')
      ? userBox.get("data")!.id ?? ""
      : "";

  static String get displayName => HiveBoxes.userBox.containsKey('data')
      ? userBox.get("data")!.displayName
      : "Contributor";

  static String get profileUrl => HiveBoxes.userBox.containsKey('data')
      ? userBox.get("data")!.profile
      : "NA";

  static Future<void> setUser(UserModel newUser) async {
    await userBox.delete("data");
    await userBox.put("data", newUser);
  }

  static Future<void> resetUser() async {
    await userBox.delete("data");
  }

  // Download Management
  static Future<void> addDownload(Map<String, dynamic> docJson) async {
    await downloadsBox.put(docJson['id'].toString(), docJson);
  }

  static List<Map<String, dynamic>> getDownloads() {
    return downloadsBox.values.cast<Map<String, dynamic>>().toList();
  }
}
