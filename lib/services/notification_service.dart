import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_data.dart';
import '../models/shopping_item.dart';
import 'notification_router.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

const String merkDirNotificationChannelId = 'merkdir_channel_v2';
const String merkDirNotificationChannelName = 'MerkDir Erinnerungen';
const String merkDirNotificationSound = 'merkdir_notification';

Future<void> initializeNotificationService() async {
  tz_data.initializeTimeZones();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  await notifications.initialize(
    settings: const InitializationSettings(android: androidSettings),
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      openNotificationPayload(response.payload);
    },
  );

  await requestNotificationPermission();
  await requestExactAlarmPermission();
  await openInitialNotificationIfNeeded();
}

Future<void> requestNotificationPermission() async {
  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

Future<void> requestExactAlarmPermission() async {
  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestExactAlarmsPermission();
}

Future<void> openInitialNotificationIfNeeded() async {
  final details = await notifications.getNotificationAppLaunchDetails();

  if (details?.didNotificationLaunchApp == true) {
    await openNotificationPayload(details?.notificationResponse?.payload);
  }
}

NotificationDetails _notificationDetails() {
  return NotificationDetails(
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
  );
}

Future<void> showStoreNotification(
  String store,
  List<ShoppingItem> items, {
  double? distance,
}) async {
  final data = NotificationData(
    store: store,
    items: items,
    distance: distance,
    createdAt: DateTime.now(),
  );

  await notifications.show(
    id: 1,
    title: '🔔 $store nearby',
    body: items.map((e) => e.name).take(3).join(', '),
    payload: data.toPayload(),
    notificationDetails: _notificationDetails(),
  );
}

Future<void> scheduleReminderNotification({
  required NotificationData data,
  required DateTime scheduledAt,
}) async {
  final id = DateTime.now().millisecondsSinceEpoch.remainder(1000000);

  await notifications.zonedSchedule(
    id: id,
    title: '🔔 ${data.store}',
    body: data.items.map((e) => e.name).take(3).join(', '),
    scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
    notificationDetails: _notificationDetails(),
    payload: data.toPayload(),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}