import 'package:flutter/material.dart';
import '../models/scan_target.dart';
import '../services/ip_parser.dart';
import '../services/scan_state.dart';

/// IP地址输入页面
class IpInputPage extends StatefulWidget {
  final ScanState scanState;

  const IpInputPage({super.key, required this.scanState});

  @override
  State<IpInputPage> createState() => _IpInputPageState();
}

class _IpInputPageState extends State<IpInputPage> {
  int _selectedMode = 0; // 0=直接IP, 1=域名, 2=网段/掩码, 3=IP范围
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  static const _modes = [
    _InputMode('直接IP', '输入IP地址，如 192.168.1.1', Icons.computer),
    _InputMode('域名解析', '输入域名，如 www.example.com', Icons.public),
    _InputMode('网段/掩码', '输入网段和掩码，如 192.168.1.0/24', Icons.share),
    _InputMode('IP范围', '输入IP范围，如 192.168.1.1:192.168.1.254', Icons.swap_horiz),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加IP目标'),
      ),
      body: Column(
        children: [
          // 模式选择
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<int>(
              segments: List.generate(
                _modes.length,
                (i) => ButtonSegment<int>(
                  value: i,
                  label: Text(_modes[i].label),
                  icon: Icon(_modes[i].icon, size: 18),
                ),
              ),
              selected: {_selectedMode},
              onSelectionChanged: (v) {
                setState(() {
                  _selectedMode = v.first;
                  _error = null;
                });
              },
            ),
          ),
          // 输入区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: _modes[_selectedMode].hint,
                hintText: _modes[_selectedMode].hint,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(_modes[_selectedMode].icon),
                errorText: _error,
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _error = null);
                        },
                      )
                    : null,
              ),
              keyboardType: _selectedMode == 1
                  ? TextInputType.url
                  : TextInputType.text,
              onSubmitted: (_) => _addTarget(),
            ),
          ),
          const SizedBox(height: 16),
          // 添加按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addTarget,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('添加到列表'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          // 当前IP列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '已添加的IP目标 (${widget.scanState.ipTargets.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (widget.scanState.ipTargets.isNotEmpty)
                  TextButton(
                    onPressed: () => widget.scanState.clearIpTargets(),
                    child: const Text('清空全部'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.scanState,
              builder: (context, _) {
                if (widget.scanState.ipTargets.isEmpty) {
                  return const Center(
                    child: Text('暂无IP目标，请添加'),
                  );
                }
                return ListView.builder(
                  itemCount: widget.scanState.ipTargets.length,
                  itemBuilder: (context, index) {
                    final target = widget.scanState.ipTargets[index];
                    return ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(target.ip),
                      subtitle: Text(target.source),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            widget.scanState.removeIpTarget(index),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTarget() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _error = '请输入内容');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<ScanTarget> targets;
      switch (_selectedMode) {
        case 0:
          targets = IpParser.parseDirectIp(input);
          if (targets.isEmpty) {
            setState(() => _error = '无效的IP地址格式');
            return;
          }
          break;
        case 1:
          targets = await IpParser.parseDomain(input);
          if (targets.isEmpty) {
            setState(() => _error = '域名解析失败，请检查域名是否正确');
            return;
          }
          break;
        case 2:
          targets = IpParser.parseSubnet(input);
          if (targets.isEmpty) {
            setState(() => _error = '无效的网段格式，请使用如 192.168.1.0/24');
            return;
          }
          break;
        case 3:
          targets = IpParser.parseIpRange(input);
          if (targets.isEmpty) {
            setState(() => _error = '无效的IP范围格式，请使用如 192.168.1.1:192.168.1.254');
            return;
          }
          break;
        default:
          return;
      }

      widget.scanState.addIpTargets(targets);
      _controller.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加 ${targets.length} 个IP目标')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _InputMode {
  final String label;
  final String hint;
  final IconData icon;
  const _InputMode(this.label, this.hint, this.icon);
}