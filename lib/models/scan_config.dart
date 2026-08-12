/// 扫描配置
class ScanConfig {
  final int timeoutMs; // 连接超时(毫秒)
  final int threadCount; // 并发线程数
  final bool enableServiceDetection; // 是否检测服务
  final bool enableBannerGrab; // 是否抓取Banner

  const ScanConfig({
    this.timeoutMs = 3000,
    this.threadCount = 100,
    this.enableServiceDetection = true,
    this.enableBannerGrab = false,
  });

  ScanConfig copyWith({
    int? timeoutMs,
    int? threadCount,
    bool? enableServiceDetection,
    bool? enableBannerGrab,
  }) {
    return ScanConfig(
      timeoutMs: timeoutMs ?? this.timeoutMs,
      threadCount: threadCount ?? this.threadCount,
      enableServiceDetection:
          enableServiceDetection ?? this.enableServiceDetection,
      enableBannerGrab: enableBannerGrab ?? this.enableBannerGrab,
    );
  }

  Duration get timeout => Duration(milliseconds: timeoutMs);
}