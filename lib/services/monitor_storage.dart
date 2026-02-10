import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/monitor.dart';

class MonitorStorage {
  static const _key = 'monitors';

  Future<List<Monitor>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    return raw
        .map((entry) => Monitor.fromMap(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Monitor> monitors) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = monitors.map((m) => jsonEncode(m.toMap())).toList();
    await prefs.setStringList(_key, raw);
  }
}
