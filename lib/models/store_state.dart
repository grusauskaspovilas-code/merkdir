class StoreState {
  final String storeId;

  bool insideZone;
  bool notificationShown;

  DateTime? lastNotification;
  DateTime? lockedUntil;
  DateTime? ignoreUntil;


  StoreState({
    required this.storeId,
    this.insideZone = false,
    this.notificationShown = false,
    this.lockedUntil,
    this.ignoreUntil,
  });
}