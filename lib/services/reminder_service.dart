class ReminderService {

  static bool isLocked(DateTime? lockedUntil) {

    if (lockedUntil == null) {
      return false;
    }

    return DateTime.now().isBefore(lockedUntil);

  }

  static DateTime lockFor(Duration duration) {

    return DateTime.now().add(duration);

  }

}