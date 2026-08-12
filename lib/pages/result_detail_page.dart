import 'package:flutter/material.dart';
import '../models/scan_result.dart';

/// 单个扫描结果详情页
class ResultDetailPage extends StatelessWidget {
  final PortScanResult result;

  const ResultDetailPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${result.ip}:${result.port}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      result.isOpen ? Icons.check_circle : Icons.cancel,
                      size: 64,
                      color: result.isOpen ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.isOpen ? '端口开放' : '端口关闭',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: result.isOpen ? Colors.green : Colors.red,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 详细信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('IP地址', result.ip),
                    const Divider(),
                    _buildInfoRow('端口', '${result.port}'),
                    const Divider(),
                    _buildInfoRow('延迟', '${result.latencyMs} ms'),
                    if (result.serviceName != null) ...[
                      const Divider(),
                      _buildInfoRow('服务', result.serviceName!),
                    ],
                    if (result.banner != null &&
                        result.banner!.isNotEmpty) ...[
                      const Divider(),
                      _buildInfoRow('Banner', result.banner!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}