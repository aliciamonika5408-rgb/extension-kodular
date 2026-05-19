import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'core/utils/formatters.dart';
import 'features/auth/screens/splash_screen.dart';

/// Android notification channel for FCM push notifications.
/// This MUST match the channel_id sent from the Edge Function FCM payload.
const AndroidNotificationChannel _fcmChannel = AndroidNotificationChannel(
  'new_orders', // channel id — matches Edge Function's android.notification.channel_id
  'Pesanan Baru', // channel name
  description: 'Notifikasi pesanan baru dari customer',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

/// Local notifications plugin for showing FCM messages when app is in foreground.
final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

// This handler will be called when a message is received while the app is in the background or terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // No need to show notification here — when FCM sends a notification payload,
  // Android system automatically shows it in background/terminated state.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set the background messaging handler early on
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // --- Create the high-priority Android notification channel ---
  // This ensures FCM notifications use our custom channel with sound + vibration.
  final androidPlugin =
      _localNotif.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(_fcmChannel);
  }

  // Initialize local notifications (for foreground FCM display)
  await _localNotif.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  // Subscribe to admin topics to receive broadcasts
  await FirebaseMessaging.instance.subscribeToTopic('admin_orders');

  // Request permission
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Set foreground notification presentation options for iOS
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // --- Handle FCM messages when app is in FOREGROUND ---
  // On Android, FCM notification payloads are NOT automatically shown when app
  // is in foreground. We must manually show them via local notifications.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _localNotif.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notification.title ?? 'Pesanan Baru',
        body: notification.body ?? '',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _fcmChannel.id,
            _fcmChannel.name,
            channelDescription: _fcmChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              notification.body ?? '',
            ),
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    }
  });

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: const Color(0xFF080A10),
  ));

  // Initialize locale data
  await Formatters.initialize();

  // Initialize Supabase with deep link handling
  await SupabaseConfig.initialize();

  // Log FCM token in debug mode only
  if (kDebugMode) {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('[FCM] Device token: $token');
  }

  runApp(const LuvenceAdminApp());
}

class LuvenceAdminApp extends StatelessWidget {
  const LuvenceAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUVENCE ID Admin',
      debugShowCheckedModeBanner: false,
      theme: LuvTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
