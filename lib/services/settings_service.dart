import 'package:shared_preferences/shared_preferences.dart';

double notificationDistance = 30;
int checkIntervalMinutes = 1;

Future<void> saveNotificationSettings() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setDouble(
    'notificationDistance',
    notificationDistance,
  );

  await prefs.setInt(
    'checkIntervalMinutes',
    checkIntervalMinutes,
  );

  print('SAVED notificationDistance = $notificationDistance');
  print('SAVED checkIntervalMinutes = $checkIntervalMinutes');
}

Future<void> loadNotificationSettings() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.reload();

  notificationDistance =
      prefs.getDouble('notificationDistance') ?? 30;

  checkIntervalMinutes =
      prefs.getInt('checkIntervalMinutes') ?? 1;

  print('LOADED notificationDistance = $notificationDistance');
  print('LOADED checkIntervalMinutes = $checkIntervalMinutes');
}