enum ReminderType {
  minutes30,
  hour1,
  hours2,
  hours5,
  hours8,
  hours10,
  tomorrow,
  nextVisit,
  ignoreToday,
}

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

  static DateTime calculate(ReminderType type) {
    final now = DateTime.now();

    switch (type) {
      case ReminderType.minutes30:
        return now.add(const Duration(minutes: 30));

      case ReminderType.hour1:
        return now.add(const Duration(hours: 1));

      case ReminderType.hours2:
        return now.add(const Duration(hours: 2));

      case ReminderType.hours5:
        return now.add(const Duration(hours: 5));

      case ReminderType.hours8:
        return now.add(const Duration(hours: 8));

      case ReminderType.hours10:
        return now.add(const Duration(hours: 10));

      case ReminderType.tomorrow:
        return DateTime(
          now.year,
          now.month,
          now.day + 1,
          8,
          0,
        );

      case ReminderType.nextVisit:
        return now;

      case ReminderType.ignoreToday:
        return DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        );
    }
  }
}