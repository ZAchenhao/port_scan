import 'dart:io';
import '../models/scan_target.dart';

/// IP地址解析器 - 支持直接IP、域名、网段、IP范围
class IpParser {
  static final _ipRegExp = RegExp(
    r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
  );

  /// 验证IP地址格式
  static bool isValidIp(String ip) {
    final match = _ipRegExp.firstMatch(ip.trim());
    if (match == null) return false;
    return match.groups([1, 2, 3, 4]).every(
      (g) => int.parse(g!) <= 255,
    );
  }

  /// 直接添加IP地址
  static List<ScanTarget> parseDirectIp(String input) {
    final ip = input.trim();
    if (isValidIp(ip)) {
      return [ScanTarget(ip: ip, source: '直接输入')];
    }
    return [];
  }

  /// 通过域名解析获取IP地址
  static Future<List<ScanTarget>> parseDomain(String domain) async {
    try {
      final addresses = await InternetAddress.lookup(domain.trim());
      final targets = <ScanTarget>[];
      for (final addr in addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          targets.add(
            ScanTarget(ip: addr.address, source: '域名解析: $domain'),
          );
        }
      }
      return targets;
    } catch (e) {
      return [];
    }
  }

  /// 解析网段和掩码，如 192.168.1.0/24
  static List<ScanTarget> parseSubnet(String input) {
    final parts = input.trim().split('/');
    if (parts.length != 2) return [];

    final ipPart = parts[0].trim();
    final maskPart = parts[1].trim();

    if (!isValidIp(ipPart)) return [];
    final mask = int.tryParse(maskPart);
    if (mask == null || mask < 0 || mask > 32) return [];

    return _generateSubnetIps(ipPart, mask, input.trim());
  }

  /// 解析IP范围，如 192.168.1.1:192.168.1.254
  static List<ScanTarget> parseIpRange(String input) {
    final parts = input.trim().split(':');
    if (parts.length != 2) return [];

    final startIp = parts[0].trim();
    final endIp = parts[1].trim();

    if (!isValidIp(startIp) || !isValidIp(endIp)) return [];

    final startNum = _ipToLong(startIp);
    final endNum = _ipToLong(endIp);

    if (startNum > endNum) return [];

    final targets = <ScanTarget>[];
    for (var i = startNum; i <= endNum; i++) {
      targets.add(
        ScanTarget(ip: _longToIp(i), source: '范围扫描: $input'),
      );
    }
    return targets;
  }

  /// 将IP地址转换为长整数
  static int _ipToLong(String ip) {
    final parts = ip.split('.').map(int.parse).toList();
    return (parts[0] << 24) + (parts[1] << 16) + (parts[2] << 8) + parts[3];
  }

  /// 将长整数转换为IP地址
  static String _longToIp(int long) {
    return '${(long >> 24) & 0xFF}.${(long >> 16) & 0xFF}.${(long >> 8) & 0xFF}.${long & 0xFF}';
  }

  /// 根据网段和掩码生成所有IP
  static List<ScanTarget> _generateSubnetIps(
    String baseIp,
    int mask,
    String sourceLabel,
  ) {
    final baseNum = _ipToLong(baseIp);
    final hostBits = 32 - mask;
    final hostCount = 1 << hostBits;
    final networkBase = baseNum & (~((1 << hostBits) - 1) & 0xFFFFFFFF);

    final targets = <ScanTarget>[];
    // 排除网络地址和广播地址(对于/31和/32特殊处理)
    final start = hostBits <= 1 ? 0 : 1;
    final end = hostBits <= 1 ? hostCount : hostCount - 1;

    for (var i = start; i < end && targets.length < 65536; i++) {
      final ip = _longToIp(networkBase + i);
      targets.add(ScanTarget(ip: ip, source: '网段扫描: $sourceLabel'));
    }
    return targets;
  }
}