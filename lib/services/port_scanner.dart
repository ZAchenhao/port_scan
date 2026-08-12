import 'dart:async';
import 'dart:io';
import '../models/scan_target.dart';
import '../models/scan_result.dart';
import '../models/scan_config.dart';
import 'service_detector.dart';

/// TCP端口扫描器 - 核心扫描引擎
class PortScanner {
  final ScanConfig config;
  final List<ScanTarget> targets;
  final List<PortEntry> ports;

  bool _cancelled = false;
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _openCount = 0;
  int _closedCount = 0;
  final List<PortScanResult> _results = [];

  final StreamController<ScanProgress> _progressController =
      StreamController<ScanProgress>.broadcast();
  final StreamController<PortScanResult> _resultController =
      StreamController<PortScanResult>.broadcast();

  Stream<ScanProgress> get progressStream => _progressController.stream;
  Stream<PortScanResult> get resultStream => _resultController.stream;

  PortScanner({
    required this.config,
    required this.targets,
    required this.ports,
  });

  /// 开始扫描
  Future<ScanSummary> scan() async {
    _cancelled = false;
    _completedTasks = 0;
    _openCount = 0;
    _closedCount = 0;
    _results.clear();
    _totalTasks = targets.length * ports.length;

    final startTime = DateTime.now();

    _emitProgress();

    // 创建任务队列
    final tasks = <_ScanTask>[];
    for (final target in targets) {
      for (final port in ports) {
        tasks.add(_ScanTask(ip: target.ip, port: port.port));
      }
    }

    // 使用信号量控制并发
    final semaphore = _Semaphore(config.threadCount);

    final futures = tasks.map((task) async {
      if (_cancelled) return;
      await semaphore.acquire();
      if (_cancelled) {
        semaphore.release();
        return;
      }

      try {
        final result = await _scanPort(task.ip, task.port);
        _completedTasks++;
        if (result.isOpen) {
          _openCount++;
        } else {
          _closedCount++;
        }
        _results.add(result);
        _resultController.add(result);
        _emitProgress();
      } finally {
        semaphore.release();
      }
    });

    await Future.wait(futures);

    final endTime = DateTime.now();

    _emitProgress();

    return ScanSummary(
      startTime: startTime,
      endTime: endTime,
      totalScanned: _completedTasks,
      openPorts: _openCount,
      closedPorts: _closedCount,
      results: List.from(_results),
    );
  }

  /// 取消扫描
  void cancel() {
    _cancelled = true;
  }

  /// 扫描单个端口
  Future<PortScanResult> _scanPort(String ip, int port) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: config.timeout,
      );

      stopwatch.stop();
      String? banner;

      if (config.enableBannerGrab) {
        try {
          socket.listen(
            (data) {
              banner = String.fromCharCodes(data).trim();
            },
            onError: (_) {},
          );
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (_) {}
      }

      socket.destroy();

      final serviceName = config.enableServiceDetection
          ? ServiceDetector.getServiceName(port)
          : null;

      return PortScanResult(
        ip: ip,
        port: port,
        isOpen: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        serviceName: serviceName,
        banner: banner,
      );
    } catch (e) {
      stopwatch.stop();
      return PortScanResult(
        ip: ip,
        port: port,
        isOpen: false,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  void _emitProgress() {
    _progressController.add(ScanProgress(
      total: _totalTasks,
      completed: _completedTasks,
      openCount: _openCount,
      closedCount: _closedCount,
      isRunning: !_cancelled && _completedTasks < _totalTasks,
    ));
  }

  void dispose() {
    _progressController.close();
    _resultController.close();
  }
}

class _ScanTask {
  final String ip;
  final int port;
  _ScanTask({required this.ip, required this.port});
}

/// 简易信号量 - 控制并发数量
class _Semaphore {
  final int maxPermits;
  int _permits;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this.maxPermits) : _permits = maxPermits;

  Future<void> acquire() async {
    if (_permits > 0) {
      _permits--;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      final completer = _waiters.removeAt(0);
      completer.complete();
    } else {
      _permits++;
    }
  }
}