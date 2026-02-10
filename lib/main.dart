import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'models/monitor.dart';
import 'services/monitor_checker.dart';
import 'services/monitor_storage.dart';
import 'services/widget_service.dart';

const _workTaskName = 'easyMonitorCheck';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final storage = MonitorStorage();
    final checker = MonitorChecker();

    final monitors = await storage.load();
    final updated = <Monitor>[];

    for (final monitor in monitors) {
      updated.add(await checker.check(monitor));
    }

    await storage.save(updated);
    await WidgetService.updateWidget(updated);

    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _workTaskName,
    _workTaskName,
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(const EasyMonitorApp());
}

class EasyMonitorApp extends StatelessWidget {
  const EasyMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyMonitor',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF0072BF),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF626668),
          onSecondary: Color(0xFFFFFFFF),
          error: Color(0xFFD32F2F),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFFF2F2F2),
          onSurface: Color(0xFF626668),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0072BF),
          foregroundColor: Color(0xFFFFFFFF),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFFFFFFF),
          surfaceTintColor: Color(0xFFFFFFFF),
        ),
        useMaterial3: true,
      ),
      home: const MonitorListPage(),
    );
  }
}

class MonitorListPage extends StatefulWidget {
  const MonitorListPage({super.key});

  @override
  State<MonitorListPage> createState() => _MonitorListPageState();
}

class _MonitorListPageState extends State<MonitorListPage> {
  final _storage = MonitorStorage();
  final _checker = MonitorChecker();
  List<Monitor> _monitors = [];
  bool _loading = true;
  bool _checking = false;
  static const _slowThresholdMs = 10000;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final monitors = await _storage.load();
    setState(() {
      _monitors = monitors;
      _loading = false;
    });
    await WidgetService.updateWidget(monitors);
  }

  Future<void> _save() async {
    await _storage.save(_monitors);
    await WidgetService.updateWidget(_monitors);
  }

  Future<void> _addMonitor() async {
    final monitor = await Navigator.of(context).push<Monitor>(
      MaterialPageRoute(builder: (_) => const AddMonitorPage()),
    );

    if (monitor == null) return;

    setState(() {
      _monitors = [..._monitors, monitor];
    });
    await _save();
  }

  Future<void> _removeMonitor(String id) async {
    setState(() {
      _monitors = _monitors.where((m) => m.id != id).toList();
    });
    await _save();
  }

  Future<void> _refreshAll() async {
    if (_checking) return;
    setState(() {
      _checking = true;
    });

    final updated = <Monitor>[];
    for (final monitor in _monitors) {
      updated.add(await _checker.check(monitor));
    }

    setState(() {
      _monitors = updated;
      _checking = false;
    });

    await _save();
  }

  Color _statusColor(Monitor monitor) {
    if (monitor.lastStatus == null) {
      return monitor.lastError == null ? Colors.grey : Colors.red;
    }
    if ((monitor.lastDurationMs ?? 0) > _slowThresholdMs) {
      return const Color(0xFFCD90F1);
    }
    final code = monitor.lastStatus!;
    if (code >= 200 && code < 300) return Colors.green;
    if (code >= 500) return Colors.red;
    return Colors.orange;
  }

  String _statusLabel(Monitor monitor) {
    if (monitor.lastStatus == null) {
      return monitor.lastError == null ? 'Sin revisar' : 'Error';
    }
    if ((monitor.lastDurationMs ?? 0) > _slowThresholdMs) {
      final seconds =
          ((monitor.lastDurationMs ?? 0) / 1000).toStringAsFixed(1);
      return 'Lento ${seconds}s';
    }
    return 'HTTP ${monitor.lastStatus}';
  }

  String _durationLabel(Monitor monitor) {
    final ms = monitor.lastDurationMs;
    if (ms == null) return '';
    return '$ms ms';
  }

  String _formatDate(DateTime? time) {
    if (time == null) return 'N/A';
    final local = time.toLocal();
    final y = local.year.toString();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyMonitor'),
        actions: [
          IconButton(
            onPressed: _checking ? null : _refreshAll,
            icon: _checking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMonitor,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _monitors.isEmpty
              ? const Center(child: Text('Agrega tus endpoints para empezar.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _monitors.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final monitor = _monitors[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _statusColor(monitor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    monitor.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${monitor.method} ${monitor.url}'),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_statusLabel(monitor)} · ${_durationLabel(monitor)} · ${_formatDate(monitor.lastChecked)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  if (monitor.lastError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        monitor.lastError!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.red[700]),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeMonitor(monitor.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class AddMonitorPage extends StatefulWidget {
  const AddMonitorPage({super.key});

  @override
  State<AddMonitorPage> createState() => _AddMonitorPageState();
}

class _AddMonitorPageState extends State<AddMonitorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  final _headersController = TextEditingController();
  String _method = 'GET';
  String _bodyType = 'JSON';

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    _headersController.dispose();
    super.dispose();
  }

  Map<String, String>? _parseHeaders(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(
              key.toString(),
              value.toString(),
            ));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _applyBodyTypeDefaults() {
    if (_method != 'POST') return;

    const contentTypeKey = 'Content-Type';
    final currentHeaders = _parseHeaders(_headersController.text) ?? {};
    if (!currentHeaders.containsKey(contentTypeKey)) {
      String contentType;
      switch (_bodyType) {
        case 'XML':
          contentType = 'text/xml; charset=utf-8';
          break;
        case 'Texto':
          contentType = 'text/plain; charset=utf-8';
          break;
        default:
          contentType = 'application/json; charset=utf-8';
      }
      currentHeaders[contentTypeKey] = contentType;
      _headersController.text = jsonEncode(currentHeaders);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final monitor = Monitor(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      method: _method,
      url: _urlController.text.trim(),
      body: _method == 'POST' ? _bodyController.text.trim() : null,
      headers: _parseHeaders(_headersController.text),
    );

    Navigator.of(context).pop(monitor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo endpoint')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://api.midominio.com/ping',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa una URL';
                  }
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null || !uri.hasScheme) {
                    return 'URL inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Método'),
                items: const [
                  DropdownMenuItem(value: 'GET', child: Text('GET')),
                  DropdownMenuItem(value: 'POST', child: Text('POST')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _method = value;
                  });
                  _applyBodyTypeDefaults();
                },
              ),
              const SizedBox(height: 12),
              if (_method == 'POST')
                DropdownButtonFormField<String>(
                  initialValue: _bodyType,
                  decoration: const InputDecoration(labelText: 'Tipo de body'),
                  items: const [
                    DropdownMenuItem(value: 'JSON', child: Text('JSON')),
                    DropdownMenuItem(value: 'XML', child: Text('XML')),
                    DropdownMenuItem(value: 'Texto', child: Text('Texto')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _bodyType = value;
                    });
                    _applyBodyTypeDefaults();
                  },
                ),
              if (_method == 'POST') const SizedBox(height: 12),
              if (_method == 'POST')
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Body (opcional)',
                    hintText: '{"ping":true}',
                  ),
                  minLines: 3,
                  maxLines: 6,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _headersController,
                decoration: const InputDecoration(
                  labelText: 'Headers JSON (opcional)',
                  hintText:
                      '{"Authorization":"Bearer ...","x-api-key":"...","Content-Type":"text/xml; charset=utf-8","SOAPAction":""}',
                ),
                minLines: 3,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  return _parseHeaders(value) == null
                      ? 'JSON inválido (debe ser objeto)'
                      : null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
