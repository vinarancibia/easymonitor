import 'dart:convert';

class Monitor {
  Monitor({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.body,
    this.headers,
    this.lastDurationMs,
    this.lastStatus,
    this.lastError,
    this.lastChecked,
  });

  final String id;
  final String name;
  final String method;
  final String url;
  final String? body;
  final Map<String, String>? headers;
  final int? lastDurationMs;
  final int? lastStatus;
  final String? lastError;
  final DateTime? lastChecked;

  Monitor copyWith({
    String? id,
    String? name,
    String? method,
    String? url,
    String? body,
    Map<String, String>? headers,
    int? lastDurationMs,
    int? lastStatus,
    String? lastError,
    DateTime? lastChecked,
  }) {
    return Monitor(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      body: body ?? this.body,
      headers: headers ?? this.headers,
      lastDurationMs: lastDurationMs ?? this.lastDurationMs,
      lastStatus: lastStatus ?? this.lastStatus,
      lastError: lastError ?? this.lastError,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'method': method,
      'url': url,
      'body': body,
      'headers': headers,
      'lastDurationMs': lastDurationMs,
      'lastStatus': lastStatus,
      'lastError': lastError,
      'lastChecked': lastChecked?.toIso8601String(),
    };
  }

  factory Monitor.fromMap(Map<String, dynamic> map) {
    return Monitor(
      id: map['id'] as String,
      name: map['name'] as String,
      method: map['method'] as String,
      url: map['url'] as String,
      body: map['body'] as String?,
      headers: (map['headers'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      lastDurationMs: map['lastDurationMs'] as int?,
      lastStatus: map['lastStatus'] as int?,
      lastError: map['lastError'] as String?,
      lastChecked: map['lastChecked'] == null
          ? null
          : DateTime.tryParse(map['lastChecked'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Monitor.fromJson(String source) =>
      Monitor.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
