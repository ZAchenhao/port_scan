import 'dart:convert';
import '../models/scan_result.dart';

/// 扫描历史记录管理
class ScanHistory {
  static final ScanHistory _instance = ScanHistory._();
  factory ScanHistory() => _instance;
  ScanHistory._();

  static const int _maxHistory = 20;
  final List<ScanHistoryEntry> _entries = [];

  List<ScanHistoryEntry> get entries => List.unmodifiable(_entries);

  void addEntry(ScanSummary summary) {
    _entries.insert(
      0,
      ScanHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch,
        summary: summary,
        timestamp: DateTime.now(),
      ),
    );
    if (_entries.length > _maxHistory) {
      _entries.removeLast();
    }
  }

  void clear() {
    _entries.clear();
  }

  void removeEntry(int id) {
    _entries.removeWhere((e) => e.id == id);
  }
}

class ScanHistoryEntry {
  final int id;
  final ScanSummary summary;
  final DateTime timestamp;

  ScanHistoryEntry({
    required this.id,
    required this.summary,
    required this.timestamp,
  });
}

/// 导出服务
class ExportService {
  /// 导出为CSV
  static String exportToCsv(ScanSummary summary) {
    final buffer = StringBuffer();
    buffer.writeln('IP,Port,Status,Latency(ms),Service,Banner');
    for (final r in summary.results) {
      buffer.writeln(
        '${r.ip},${r.port},${r.isOpen ? "Open" : "Closed"},${r.latencyMs},${r.serviceName ?? ""},${r.banner ?? ""}',
      );
    }
    return buffer.toString();
  }

  /// 导出为JSON
  static String exportToJson(ScanSummary summary) {
    final data = summary.results
        .map((r) => {
              'ip': r.ip,
              'port': r.port,
              'isOpen': r.isOpen,
              'latencyMs': r.latencyMs,
              'serviceName': r.serviceName,
              'banner': r.banner,
            })
        .toList();

    return const JsonEncoder.withIndent('  ').convert({
      'scanTime': summary.startTime.toIso8601String(),
      'duration': summary.duration.inMilliseconds,
      'totalScanned': summary.totalScanned,
      'openPorts': summary.openPorts,
      'closedPorts': summary.closedPorts,
      'results': data,
    });
  }
}