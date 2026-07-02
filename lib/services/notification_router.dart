import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../models/notification_data.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? _pendingNotificationPayload;

Future<void> openNotificationPayload(String? payload) async {
  if (payload == null || payload.trim().isEmpty) return;

  final navigator = navigatorKey.currentState;

  if (navigator == null) {
    _pendingNotificationPayload = payload;
    return;
  }

  try {
    final data = NotificationData.fromPayload(payload);

    if (data.store.trim().isEmpty) return;

    navigator.pushNamed(
      AppRoutes.notification,
      arguments: data,
    );
  } catch (e) {
    debugPrint('Notification payload error: $e');
  }
}

Future<void> openPendingNotificationIfAny() async {
  final payload = _pendingNotificationPayload;
  _pendingNotificationPayload = null;

  await openNotificationPayload(payload);
}
