import 'package:flutter/material.dart';
import '../services/scan_state.dart';
import '../services/scan_history.dart';
import 'result_detail_page.dart';

/// 扫描历史页面
class HistoryPage extends StatelessWidget {
  final ScanState scanState;

  const HistoryPage({super.key, required this.scanState});

  @override
  Widget build(BuildContext context) {
    final history = scanState.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描历史'),
        actions: [
          if (history.entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('清空历史'),
                    content: const Text('确定要清空所有扫描历史吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          history.clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text('清空',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: '清空历史',
            ),
        ],
      ),
      body: history.entries.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无扫描历史', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: history.entries.length,
              itemBuilder: (context, index) {
                final entry = history.entries[index];
                return _buildHistoryCard(context, entry);
              },
            ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ScanHistoryEntry entry) {
    final summary = entry.summary;
    final timeStr =
        '${entry.timestamp.year}-${entry.timestamp.month.toString().padLeft(2, '0')}-${entry.timestamp.day.toString().padLeft(2, '0')} '
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: summary.openPorts > 0
              ? Colors.green.shade100
              : Colors.grey.shade200,
          child: Icon(
            summary.openPorts > 0 ? Icons.check : Icons.search,
            color: summary.openPorts > 0 ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          '发现 ${summary.openPorts} 个开放端口',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$timeStr | ${summary.totalScanned}次扫描 | ${_formatDuration(summary.duration)}',
        ),
        children: [
          // 统计信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildMiniStat('开放', '${summary.openPorts}', Colors.green),
                const SizedBox(width: 16),
                _buildMiniStat('关闭', '${summary.closedPorts}', Colors.red),
                const SizedBox(width: 16),
                _buildMiniStat('耗时', _formatDuration(summary.duration),
                    Colors.blue),
              ],
            ),
          ),
          // 开放端口列表
          if (summary.results.any((r) => r.isOpen)) ...[
            const Divider(),
            ...summary.results
                .where((r) => r.isOpen)
                .take(20)
                .map((r) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      title: Text('${r.ip}:${r.port}'),
                      subtitle: r.serviceName != null
                          ? Text(r.serviceName!)
                          : null,
                      trailing: Text('${r.latencyMs}ms'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ResultDetailPage(result: r),
                          ),
                        );
                      },
                    )),
            if (summary.openPorts > 20)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '... 还有 ${summary.openPorts - 20} 个开放端口',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}秒';
    if (d.inMinutes < 60) return '${d.inMinutes}分${d.inSeconds % 60}秒';
    return '${d.inHours}时${d.inMinutes % 60}分';
  }
}