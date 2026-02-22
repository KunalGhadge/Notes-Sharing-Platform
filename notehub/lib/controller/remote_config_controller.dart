import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemoteConfigController extends GetxController {
  final supabase = Supabase.instance.client;
  var config = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchConfig();
    listenToConfig();
  }

  Future<void> fetchConfig() async {
    try {
      final response = await supabase.from('remote_config').select();
      final Map<String, dynamic> tmp = {};
      for (var row in (response as List)) {
        tmp[row['key']] = row['value'];
      }
      config.value = tmp;
    } catch (e) {
      // Silent fail for remote config
    }
  }

  void listenToConfig() {
    supabase
        .channel('public:remote_config')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'remote_config',
          callback: (payload) {
            fetchConfig();
          },
        )
        .subscribe();
  }

  String getAnnouncement() => config['global_announcement'] ?? "";
  bool isMaintenanceMode() => config['maintenance_mode'] ?? false;
}
