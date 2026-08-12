/// 扫描目标模型 - 表示一个IP地址目标
class ScanTarget {
  final String ip;
  final String source; // 来源描述: 直接输入 / 域名解析 / 网段扫描 / 范围扫描

  const ScanTarget({
    required this.ip,
    required this.source,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScanTarget && ip == other.ip;

  @override
  int get hashCode => ip.hashCode;

  @override
  String toString() => '$ip ($source)';
}

/// 端口条目模型
class PortEntry {
  final int port;
  final String source; // 来源描述: 直接输入 / 范围扫描 / 常用端口

  const PortEntry({
    required this.port,
    required this.source,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PortEntry && port == other.port;

  @override
  int get hashCode => port.hashCode;

  @override
  String toString() => '$port ($source)';
}