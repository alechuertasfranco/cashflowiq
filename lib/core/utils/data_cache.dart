class DataCache {
  static final DataCache _instance = DataCache._();
  DataCache._();
  static DataCache get instance => _instance;

  final Map<String, _CacheEntry> _store = {};
  final Duration ttl = const Duration(minutes: 5);

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.fetchedAt) > ttl) {
      _store.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  void set(String key, dynamic data) {
    _store[key] = _CacheEntry(data: data, fetchedAt: DateTime.now());
  }

  void invalidate(String key) => _store.remove(key);

  void invalidatePrefix(String prefix) =>
      _store.removeWhere((k, _) => k.startsWith(prefix));

  void clear() => _store.clear();
}

class _CacheEntry {
  final dynamic data;
  final DateTime fetchedAt;
  const _CacheEntry({required this.data, required this.fetchedAt});
}
