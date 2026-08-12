import 'package:flutter/foundation.dart';
import '../models/scan_target.dart';
import '../models/scan_result.dart';
import '../models/scan_config.dart';
import '../services/port_scanner.dart';
import '../services/scan_history.dart';

/// 扫描状态管理
class ScanState extends ChangeNotifier {
  // IP目标列表
  final List<ScanTarget> _ipTargets = [];
  List<ScanTarget> get ipTargets => List.unmodifiable(_ipTargets);

  // 端口列表
  final List<PortEntry> _portEntries = [];
  List<PortEntry> get portEntries => List.unmodifiable(_portEntries);

  // 扫描配置
  ScanConfig _config = const ScanConfig();
  ScanConfig get config => _config;

  // 扫描状态
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // 扫描进度
  ScanProgress? _progress;
  ScanProgress? get progress => _progress;

  // 扫描结果
  final List<PortScanResult> _results = [];
  List<PortScanResult> get results => List.unmodifiable(_results);
  List<PortScanResult> get openResults =>
      _results.where((r) => r.isOpen).toList();

  // 扫描摘要
  ScanSummary? _lastSummary;
  ScanSummary? get lastSummary => _lastSummary;

  // 扫描器实例
  PortScanner? _scanner;

  // 历史记录
  final ScanHistory _history = ScanHistory();
  ScanHistory get history => _history;

  // --- IP目标管理 ---

  void addIpTarget(ScanTarget target) {
    if (!_ipTargets.any((t) => t.ip == target.ip)) {
      _ipTargets.add(target);
      notifyListeners();
    }
  }

  void addIpTargets(List<ScanTarget> targets) {
    var added = false;
    for (final t in targets) {
      if (!_ipTargets.any((existing) => existing.ip == t.ip)) {
        _ipTargets.add(t);
        added = true;
      }
    }
    if (added) notifyListeners();
  }

  void removeIpTarget(int index) {
    _ipTargets.removeAt(index);
    notifyListeners();
  }

  void clearIpTargets() {
    _ipTargets.clear();
    notifyListeners();
  }

  // --- 端口管理 ---

  void addPortEntry(PortEntry entry) {
    if (!_portEntries.any((p) => p.port == entry.port)) {
      _portEntries.add(entry);
      _portEntries.sort((a, b) => a.port.compareTo(b.port));
      notifyListeners();
    }
  }

  void addPortEntries(List<PortEntry> entries) {
    var added = false;
    for (final e in entries) {
      if (!_portEntries.any((p) => p.port == e.port)) {
        _portEntries.add(e);
        added = true;
      }
    }
    if (added) {
      _portEntries.sort((a, b) => a.port.compareTo(b.port));
      notifyListeners();
    }
  }

  void removePortEntry(int index) {
    _portEntries.removeAt(index);
    notifyListeners();
  }

  void clearPortEntries() {
    _portEntries.clear();
    notifyListeners();
  }

  // --- 配置管理 ---

  void updateConfig(ScanConfig config) {
    _config = config;
    notifyListeners();
  }

  // --- 扫描控制 ---

  bool get canScan =>
      _ipTargets.isNotEmpty && _portEntries.isNotEmpty && !_isScanning;

  int get totalTasks => _ipTargets.length * _portEntries.length;

  Future<void> startScan() async {
    if (!canScan) return;

    _isScanning = true;
    _results.clear();
    _lastSummary = null;
    _progress = null;
    notifyListeners();

    _scanner = PortScanner(
      config: _config,
      targets: _ipTargets,
      ports: _portEntries,
    );

    _scanner!.progressStream.listen((p) {
      _progress = p;
      notifyListeners();
    });

    _scanner!.resultStream.listen((r) {
      _results.add(r);
    });

    final summary = await _scanner!.scan();
    _lastSummary = summary;
    _progress = ScanProgress(
      total: summary.totalScanned,
      completed: summary.totalScanned,
      openCount: summary.openPorts,
      closedCount: summary.closedPorts,
      isRunning: false,
    );
    _isScanning = false;
    _history.addEntry(summary);
    notifyListeners();
  }

  void cancelScan() {
    _scanner?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanner?.dispose();
    super.dispose();
  }
}