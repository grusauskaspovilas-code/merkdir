import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

Future<void> showStoreNotification(
  String store,
  List<String> items,
) async {
  await notifications.show(
    1,
    '🔔 $store nearby',
    items.take(3).join(', '),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'merkdir_channel',
        'MerkDir Erinnerungen',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );
}