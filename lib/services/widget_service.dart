import 'package:home_widget/home_widget.dart';

import '../models/monitor.dart';

class WidgetService {
  static const _androidWidgetName = 'EasyMonitorWidgetProvider';
  static const _maxItems = 4;

  static int statusToCode(Monitor monitor) {
    if (monitor.lastStatus == null) {
      return monitor.lastError == null ? 0 : 2;
    }
    if ((monitor.lastDurationMs ?? 0) > 10000) return 4;
    final code = monitor.lastStatus!;
    if (code >= 200 && code < 300) return 1;
    if (code >= 500) return 2;
    return 3;
  }

  static Future<void> updateWidget(List<Monitor> monitors) async {
    final sorted = [...monitors]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final count = sorted.length.clamp(0, _maxItems);
    await HomeWidget.saveWidgetData('item_count', count);

    for (var i = 0; i < _maxItems; i += 1) {
      if (i < count) {
        final item = sorted[i];
        await HomeWidget.saveWidgetData('item_name_$i', item.name);
        await HomeWidget.saveWidgetData('item_status_$i', statusToCode(item));
      } else {
        await HomeWidget.saveWidgetData('item_name_$i', '');
        await HomeWidget.saveWidgetData('item_status_$i', 0);
      }
    }

    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }
}
