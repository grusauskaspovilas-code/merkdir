import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_data.dart';
import '../models/shopping_item.dart';
import 'notification_router.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

String? lastNotifiedStore;
DateTime? lastNotificationTime;

const String merkDirNotificationChannelId = 'merkdir_channel_v2';
const String merkDirNotificationChannelName = 'MerkDir Erinnerungen';
const String merkDirNotificationSound = 'merkdir_notification';

Future<void> initializeNotificationService() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  await notifications.initialize(
    settings: const InitializationSettings(android: androidSettings),
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      openNotificationPayload(response.payload);
    },
  );

  await requestNotificationPermission();
  await openInitialNotificationIfNeeded();
}

Future<void> requestNotificationPermission() async {
  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

Future<void> openInitialNotificationIfNeeded() async {
  final details = await notifications.getNotificationAppLaunchDetails();

  if (details?.didNotificationLaunchApp == true) {
    await openNotificationPayload(details?.notificationResponse?.payload);
  }
}

Future<void> showStoreNotification(
  String store,
  List<ShoppingItem> items,
) async {
  final data = NotificationData(store: store, items: items);

  await notifications.show(
    id: 1,
    title: '🔔 $store nearby',
    body: items.map((e) => e.name).take(3).join(', '),
    payload: data.toPayload(),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        merkDirNotificationChannelId,
        merkDirNotificationChannelName,
        channelDescription: 'Notifications when shopping items are nearby',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          merkDirNotificationSound,
        ),
        enableVibration: true,
        color: const Color(0xFFFF8C00),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      ),
    ),
  );
}
