import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:notehub/core/meta/app_meta.dart';
import 'package:notehub/controller/bottom_navigation_controller.dart';
import 'package:notehub/controller/notification_controller.dart';
import 'package:notehub/controller/showcase_controller.dart';
import 'package:notehub/model/user_model.dart';
import 'package:notehub/view/splash_screen/splash.dart';
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppMetaData.supabaseUrl,
    anonKey: AppMetaData.supabaseAnonKey,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: android);
  await flutterLocalNotificationsPlugin.initialize(settings: initSettings);

  // Create Android Notification Channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'notes_channel',
    'Notes Notifications',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<UserModel>("user");
  Get.put(BottomNavigationController());
  Get.put(NotificationController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: GetMaterialApp(
        title: AppMetaData.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
          useMaterial3: true,
        ),
        home: const Splash(),
      ),
    );
  }
}
