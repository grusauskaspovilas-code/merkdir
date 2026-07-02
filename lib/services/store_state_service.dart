import '../models/store_state.dart';

class StoreStateService {
  static final Map<String, StoreState> _stores = {};

  static StoreState get(String storeId) {
    return _stores.putIfAbsent(
      storeId,
      () => StoreState(storeId: storeId),
    );
  }

  static void clear() {
    _stores.clear();
  }
}