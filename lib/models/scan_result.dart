/// 单个端口扫描结果
class PortScanResult {
  final String ip;
  final int port;
  final bool isOpen;
  final int latencyMs;
  final String? serviceName;
  final String? banner;

  const PortScanResult({
    required this.ip,
    required this.port,
    required this.isOpen,
    required this.latencyMs,
    this.serviceName,
    this.banner,
  });

  String get key => '$ip:$port';
}

/// 扫描进度
class ScanProgress {
  final int total;
  final int completed;
  final int openCount;
  final int closedCount;
  final bool isRunning;

  const ScanProgress({
    required this.total,
    required this.completed,
    required this.openCount,
    required this.closedCount,
    required this.isRunning,
  });

  double get percentage => total > 0 ? completed / total : 0;
}

/// 扫描结果汇总
class ScanSummary {
  final DateTime startTime;
  final DateTime? endTime;
  final int totalScanned;
  final int openPorts;
  final int closedPorts;
  final List<PortScanResult> results;

  const ScanSummary({
    required this.startTime,
    this.endTime,
    required this.totalScanned,
    required this.openPorts,
    required this.closedPorts,
    required this.results,
  });

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);
}