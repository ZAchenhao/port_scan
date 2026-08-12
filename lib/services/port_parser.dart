import '../models/scan_target.dart';

/// 端口解析器 - 支持直接端口、端口范围、常用端口
class PortParser {
  static const _maxPort = 65535;
  static const _minPort = 1;

  /// 验证端口是否有效
  static bool isValidPort(int port) {
    return port >= _minPort && port <= _maxPort;
  }

  /// 直接添加端口
  static List<PortEntry> parseDirectPort(String input) {
    final port = int.tryParse(input.trim());
    if (port != null && isValidPort(port)) {
      return [PortEntry(port: port, source: '直接输入')];
    }
    return [];
  }

  /// 解析端口范围，如 1:1024
  static List<PortEntry> parsePortRange(String input) {
    final parts = input.trim().split(':');
    if (parts.length != 2) return [];

    final startPort = int.tryParse(parts[0].trim());
    final endPort = int.tryParse(parts[1].trim());

    if (startPort == null || endPort == null) return [];
    if (!isValidPort(startPort) || !isValidPort(endPort)) return [];
    if (startPort > endPort) return [];

    final entries = <PortEntry>[];
    for (var i = startPort; i <= endPort; i++) {
      entries.add(PortEntry(port: i, source: '范围扫描: $input'));
    }
    return entries;
  }

  /// 常用端口列表
  static List<PortEntry> getCommonPorts() {
    return _commonPorts
        .map((e) => PortEntry(port: e.port, source: '常用端口'))
        .toList();
  }

  /// 常用端口定义
  static List<CommonPort> get commonPortDefinitions =>
      _commonPorts.map((e) => CommonPort(port: e.port, serviceName: e.serviceName, description: e.description)).toList();
}

class CommonPort {
  final int port;
  final String serviceName;
  final String description;

  const CommonPort({
    required this.port,
    required this.serviceName,
    required this.description,
  });
}

const _commonPorts = <CommonPort>[
  CommonPort(port: 21, serviceName: 'FTP', description: '文件传输协议'),
  CommonPort(port: 22, serviceName: 'SSH', description: '安全外壳协议'),
  CommonPort(port: 23, serviceName: 'Telnet', description: '远程登录协议'),
  CommonPort(port: 25, serviceName: 'SMTP', description: '简单邮件传输协议'),
  CommonPort(port: 53, serviceName: 'DNS', description: '域名系统'),
  CommonPort(port: 80, serviceName: 'HTTP', description: '超文本传输协议'),
  CommonPort(port: 110, serviceName: 'POP3', description: '邮局协议v3'),
  CommonPort(port: 143, serviceName: 'IMAP', description: '互联网消息访问协议'),
  CommonPort(port: 443, serviceName: 'HTTPS', description: '安全超文本传输协议'),
  CommonPort(port: 993, serviceName: 'IMAPS', description: '安全IMAP'),
  CommonPort(port: 995, serviceName: 'POP3S', description: '安全POP3'),
  CommonPort(port: 3306, serviceName: 'MySQL', description: 'MySQL数据库'),
  CommonPort(port: 3389, serviceName: 'RDP', description: '远程桌面协议'),
  CommonPort(port: 5432, serviceName: 'PostgreSQL', description: 'PostgreSQL数据库'),
  CommonPort(port: 6379, serviceName: 'Redis', description: 'Redis缓存'),
  CommonPort(port: 8080, serviceName: 'HTTP-Alt', description: 'HTTP备用端口'),
  CommonPort(port: 8443, serviceName: 'HTTPS-Alt', description: 'HTTPS备用端口'),
  CommonPort(port: 27017, serviceName: 'MongoDB', description: 'MongoDB数据库'),
  CommonPort(port: 5000, serviceName: 'UPnP', description: '通用即插即用'),
  CommonPort(port: 9090, serviceName: 'WebSocket', description: 'WebSocket代理'),
  CommonPort(port: 9200, serviceName: 'Elasticsearch', description: 'Elasticsearch'),
  CommonPort(port: 11211, serviceName: 'Memcached', description: 'Memcached缓存'),
];