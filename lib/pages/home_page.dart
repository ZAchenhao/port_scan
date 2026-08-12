import 'package:flutter/material.dart';
import '../services/scan_state.dart';
import 'ip_input_page.dart';
import 'port_input_page.dart';
import 'scan_page.dart';
import 'settings_page.dart';
import 'history_page.dart';

class HomePage extends StatelessWidget {
  final ScanState scanState;

  const HomePage({super.key, required this.scanState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('端口扫描工具'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryPage(scanState: scanState),
                ),
              );
            },
            tooltip: '扫描历史',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(scanState: scanState),
                ),
              );
            },
            tooltip: '扫描设置',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: scanState,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // IP目标卡片
                _buildTargetCard(
                  context,
                  icon: Icons.language,
                  title: 'IP目标列表',
                  count: scanState.ipTargets.length,
                  subtitle: scanState.ipTargets.isEmpty
                      ? '暂无IP目标'
                      : '${scanState.ipTargets.length} 个IP地址',
                  onTap: () => _navigateToIpInput(context),
                  onClear: scanState.ipTargets.isNotEmpty
                      ? () => scanState.clearIpTargets()
                      : null,
                ),
                const SizedBox(height: 12),
                // 端口卡片
                _buildTargetCard(
                  context,
                  icon: Icons.dns,
                  title: '端口列表',
                  count: scanState.portEntries.length,
                  subtitle: scanState.portEntries.isEmpty
                      ? '暂无端口'
                      : '${scanState.portEntries.length} 个端口',
                  onTap: () => _navigateToPortInput(context),
                  onClear: scanState.portEntries.isNotEmpty
                      ? () => scanState.clearPortEntries()
                      : null,
                ),
                const SizedBox(height: 12),
                // 扫描信息卡片
                if (scanState.ipTargets.isNotEmpty &&
                    scanState.portEntries.isNotEmpty)
                  _buildScanInfoCard(),
                const Spacer(),
                // 扫描按钮
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: scanState.canScan
                        ? () => _startScan(context)
                        : null,
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: Text(
                      scanState.canScan
                          ? '开始扫描 (${scanState.ipTargets.length} IP x ${scanState.portEntries.length} 端口 = ${scanState.totalTasks} 次)'
                          : '请先添加IP目标和端口',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: count > 0 ? Colors.green : Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: onClear,
                  tooltip: '清空列表',
                ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanInfoCard() {
    return Card(
      elevation: 1,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '将扫描 ${scanState.ipTargets.length} 个IP地址的 ${scanState.portEntries.length} 个端口，共 ${scanState.totalTasks} 次探测',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToIpInput(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IpInputPage(scanState: scanState),
      ),
    );
  }

  void _navigateToPortInput(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PortInputPage(scanState: scanState),
      ),
    );
  }

  void _startScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPage(scanState: scanState),
      ),
    );
  }
}