import '../models/store_state.dart';

class StoreStateService {
  static final Map<String, StoreState> _states = {};

  static StoreState getState(String storeId) {
    return _states.putIfAbsent(
      storeId,
      () => StoreState(storeId: storeId),
    );
  }

  static void clear() {
    _states.clear();
  }

  static void remove(String storeId) {
    _states.remove(storeId);
  }
}