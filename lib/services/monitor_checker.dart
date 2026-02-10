import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/monitor.dart';

class MonitorChecker {
  Future<Monitor> check(Monitor monitor) async {
    try {
      final uri = Uri.parse(monitor.url);
      http.Response response;
      final method = monitor.method.toUpperCase();
      final headers = <String, String>{
        if (monitor.headers != null) ...monitor.headers!,
      };
      final headerContentType =
          headers['Content-Type'] ?? headers['content-type'];
      final stopwatch = Stopwatch()..start();

      if (method == 'POST') {
        final body = monitor.body?.trim();
        final contentType =
            headerContentType ?? 'application/json; charset=utf-8';
        headers['Content-Type'] = contentType;
        final shouldNormalizeJson = contentType.contains('application/json');
        response = await http
            .post(
              uri,
              headers: headers,
              body: body != null && body.isNotEmpty
                  ? (shouldNormalizeJson ? _normalizeJson(body) : body)
                  : null,
            )
            .timeout(const Duration(seconds: 15));
      } else {
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
      }
      stopwatch.stop();

      return monitor.copyWith(
        lastStatus: response.statusCode,
        lastError: null,
        lastDurationMs: stopwatch.elapsedMilliseconds,
        lastChecked: DateTime.now(),
      );
    } on TimeoutException catch (_) {
      return monitor.copyWith(
        lastStatus: null,
        lastError: 'timeout',
        lastDurationMs: 15000,
        lastChecked: DateTime.now(),
      );
    } catch (error) {
      return monitor.copyWith(
        lastStatus: null,
        lastError: error.toString(),
        lastDurationMs: null,
        lastChecked: DateTime.now(),
      );
    }
  }

  String _normalizeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return jsonEncode(decoded);
    } catch (_) {
      return raw;
    }
  }
}
