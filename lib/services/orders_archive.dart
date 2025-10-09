import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Archive locale de commandes fournisseur (toutes statuses).
/// On stocke un Map<int, Map> { id: orderJson } en SharedPreferences.
class OrdersArchive {
  OrdersArchive._();
  static final OrdersArchive instance = OrdersArchive._();

  static const _key = 'supplier_orders_archive_v1';

  Map<int, Map<String, dynamic>> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _cache = map.map((k, v) => MapEntry(int.parse(k), Map<String, dynamic>.from(v as Map)));
      } catch (_) {
        _cache = {};
      }
    }
    _loaded = true;
  }

  Future<List<Map<String, dynamic>>> listAll() async {
    await _ensureLoaded();
    return _cache.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>?> get(int id) async {
    await _ensureLoaded();
    final v = _cache[id];
    return v == null ? null : Map<String, dynamic>.from(v);
  }

  Future<void> upsert(Map<String, dynamic> orderJson) async {
    await _ensureLoaded();
    final id = (orderJson['id'] as num?)?.toInt();
    if (id == null) return;
    _cache[id] = Map<String, dynamic>.from(orderJson);
    await _persist();
  }

  Future<void> remove(int id) async {
    await _ensureLoaded();
    _cache.remove(id);
    await _persist();
  }

  Future<void> clear() async {
    _cache.clear();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final str = jsonEncode(_cache.map((k, v) => MapEntry(k.toString(), v)));
    await prefs.setString(_key, str);
  }
}
