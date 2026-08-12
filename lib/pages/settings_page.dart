import 'package:flutter/material.dart';
import '../models/scan_config.dart';
import '../services/scan_state.dart';

/// 扫描设置页面
class SettingsPage extends StatefulWidget {
  final ScanState scanState;

  const SettingsPage({super.key, required this.scanState});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _timeoutController;
  late TextEditingController _threadController;
  late bool _enableServiceDetection;
  late bool _enableBannerGrab;

  @override
  void initState() {
    super.initState();
    final config = widget.scanState.config;
    _timeoutController =
        TextEditingController(text: config.timeoutMs.toString());
    _threadController =
        TextEditingController(text: config.threadCount.toString());
    _enableServiceDetection = config.enableServiceDetection;
    _enableBannerGrab = config.enableBannerGrab;
  }

  @override
  void dispose() {
    _timeoutController.dispose();
    _threadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描设置'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 超时设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        '连接超时',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _timeoutController,
                    decoration: const InputDecoration(
                      labelText: '超时时间（毫秒）',
                      hintText: '3000',
                      border: OutlineInputBorder(),
                      suffixText: 'ms',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '建议范围: 1000-10000ms。值越小扫描越快但可能漏报，值越大越准确但扫描越慢。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  // 快捷选择
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [1000, 2000, 3000, 5000, 10000].map((ms) {
                      return ChoiceChip(
                        label: Text('${ms}ms'),
                        selected: _timeoutController.text == ms.toString(),
                        onSelected: (_) {
                          _timeoutController.text = ms.toString();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 线程设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        '并发线程数',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _threadController,
                    decoration: const InputDecoration(
                      labelText: '线程数',
                      hintText: '100',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '建议范围: 10-500。线程数越多扫描越快，但可能触发防火墙限制或导致网络拥塞。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [10, 50, 100, 200, 500].map((count) {
                      return ChoiceChip(
                        label: Text('$count'),
                        selected: _threadController.text == count.toString(),
                        onSelected: (_) {
                          _threadController.text = count.toString();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 功能开关
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.toggle_on, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Text(
                        '功能选项',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('服务识别'),
                    subtitle: const Text('根据端口号识别常见服务名称'),
                    value: _enableServiceDetection,
                    onChanged: (v) {
                      setState(() => _enableServiceDetection = v);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Banner抓取'),
                    subtitle: const Text('尝试获取开放端口返回的Banner信息（会略微增加扫描时间）'),
                    value: _enableBannerGrab,
                    onChanged: (v) {
                      setState(() => _enableBannerGrab = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 说明信息
          Card(
            color: Colors.amber.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        '注意事项',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. 请确保您有权扫描目标IP地址。\n'
                    '2. 未经授权的端口扫描可能违反法律法规。\n'
                    '3. 高并发扫描可能触发防火墙规则。\n'
                    '4. 建议先使用较长超时时间确保准确性。',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _saveSettings() {
    final timeoutMs = int.tryParse(_timeoutController.text) ?? 3000;
    final threadCount = int.tryParse(_threadController.text) ?? 100;

    final config = ScanConfig(
      timeoutMs: timeoutMs.clamp(100, 60000),
      threadCount: threadCount.clamp(1, 1000),
      enableServiceDetection: _enableServiceDetection,
      enableBannerGrab: _enableBannerGrab,
    );

    widget.scanState.updateConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存')),
      );
      Navigator.pop(context);
    }
  }
}