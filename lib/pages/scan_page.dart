import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/scan_result.dart';
import '../services/scan_state.dart';
import '../services/scan_history.dart';
import 'result_detail_page.dart';

/// 扫描进度和结果页面
class ScanPage extends StatefulWidget {
  final ScanState scanState;

  const ScanPage({super.key, required this.scanState});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  @override
  void initState() {
    super.initState();
    // 自动开始扫描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.scanState.startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.scanState.isScanning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.scanState.isScanning) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('扫描进度'),
          actions: [
            if (widget.scanState.isScanning)
              TextButton.icon(
                onPressed: _showCancelDialog,
                icon: const Icon(Icons.stop, color: Colors.red),
                label: const Text('停止', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        body: ListenableBuilder(
          listenable: widget.scanState,
          builder: (context, _) {
            final progress = widget.scanState.progress;
            final isRunning = widget.scanState.isScanning;

            if (progress == null && !isRunning) {
              return const Center(child: Text('准备扫描...'));
            }

            return Column(
              children: [
                // 进度区域
                _buildProgressSection(progress),
                // 统计信息
                _buildStatsSection(),
                // 结果列表
                Expanded(child: _buildResultList()),
                // 底部操作栏
                if (!isRunning && widget.scanState.lastSummary != null)
                  _buildBottomActions(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressSection(ScanProgress? progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress?.percentage ?? 0,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 12),
          // 进度文字
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress?.completed ?? 0} / ${progress?.total ?? 0}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${((progress?.percentage ?? 0) * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final summary = widget.scanState.lastSummary;
    final progress = widget.scanState.progress;
    final openCount = summary?.openPorts ?? progress?.openCount ?? 0;
    final closedCount = summary?.closedPorts ?? progress?.closedCount ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
            '开放端口',
            '$openCount',
            Colors.green,
            Icons.check_circle,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            '关闭端口',
            '$closedCount',
            Colors.red,
            Icons.cancel,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            '总计',
            '${openCount + closedCount}',
            Colors.blue,
            Icons.info,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        color: color.withAlpha(25),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultList() {
    final results = widget.scanState.results;
    // 只显示开放端口，按IP和端口排序
    final openResults = results.where((r) => r.isOpen).toList()
      ..sort((a, b) {
        final ipCompare = a.ip.compareTo(b.ip);
        if (ipCompare != 0) return ipCompare;
        return a.port.compareTo(b.port);
      });

    final isRunning = widget.scanState.isScanning;

    if (openResults.isEmpty && !isRunning && results.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('未发现开放端口', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (openResults.isEmpty && isRunning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('扫描中...'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '开放端口 (${openResults.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (isRunning)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: openResults.length,
            itemBuilder: (context, index) {
              final result = openResults[index];
              return _buildResultItem(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(PortScanResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.check, color: Colors.green),
        ),
        title: Text(
          '${result.ip}:${result.port}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            if (result.serviceName != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.serviceName!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${result.latencyMs}ms',
              style: TextStyle(
                color: result.latencyMs < 100 ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultDetailPage(result: result),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _copyResults(),
              icon: const Icon(Icons.copy),
              label: const Text('复制结果'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _exportResults(),
              icon: const Icon(Icons.download),
              label: const Text('导出结果'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('停止扫描'),
        content: const Text('确定要停止当前扫描吗？已扫描的结果将保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('继续扫描'),
          ),
          TextButton(
            onPressed: () {
              widget.scanState.cancelScan();
              Navigator.pop(ctx);
            },
            child: const Text('停止', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _copyResults() {
    final openResults = widget.scanState.openResults;
    if (openResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有开放端口可复制')),
      );
      return;
    }

    final text = openResults
        .map((r) =>
            '${r.ip}:${r.port}\t${r.serviceName ?? ""}\t${r.latencyMs}ms')
        .join('\n');

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制 ${openResults.length} 条结果到剪贴板')),
    );
  }

  void _exportResults() {
    final summary = widget.scanState.lastSummary;
    if (summary == null) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '导出结果',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('导出为 CSV'),
                subtitle: const Text('表格格式，可用Excel打开'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showExportResult(ExportService.exportToCsv(summary),
                      'csv');
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('导出为 JSON'),
                subtitle: const Text('结构化数据格式'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showExportResult(
                      ExportService.exportToJson(summary), 'json');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportResult(String content, String format) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('导出为 $format'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('复制到剪贴板'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}