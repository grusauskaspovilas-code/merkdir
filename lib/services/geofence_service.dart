import '../models/store_state.dart';

class GeofenceService {
  static bool shouldNotify({
    required StoreState state,
    required double distance,
    required double notificationDistance,
  }) {
    final exitDistance = notificationDistance + 30;

    if (distance > exitDistance) {
      state.insideZone = false;
      state.notificationShown = false;
      return false;
    }

    if (distance > notificationDistance) {
      return false;
    }

    if (state.notificationShown) {
      return false;
    }

    state.insideZone = true;
    state.notificationShown = true;

    return true;
  }
}