import 'package:flutter/material.dart';
import '../models/scan_target.dart';
import '../services/port_parser.dart';
import '../services/scan_state.dart';

/// 端口输入页面
class PortInputPage extends StatefulWidget {
  final ScanState scanState;

  const PortInputPage({super.key, required this.scanState});

  @override
  State<PortInputPage> createState() => _PortInputPageState();
}

class _PortInputPageState extends State<PortInputPage> {
  int _selectedMode = 0; // 0=直接端口, 1=端口范围, 2=常用端口
  final _controller = TextEditingController();
  String? _error;

  // 常用端口选中状态
  final Set<int> _selectedCommonPorts = {};

  static const _modes = [
    _PortMode('直接端口', '输入端口号，如 22', Icons.numbers),
    _PortMode('端口范围', '输入端口范围，如 1:1024', Icons.swap_horiz),
    _PortMode('常用端口', '从常用端口列表中选择', Icons.star),
  ];

  @override
  void initState() {
    super.initState();
    // 初始化选中状态
    for (final entry in widget.scanState.portEntries) {
      _selectedCommonPorts.add(entry.port);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加端口'),
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
          // 输入区域 (模式0和1)
          if (_selectedMode != 2) ...[
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
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _addPort(),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _addPort,
                  icon: const Icon(Icons.add),
                  label: const Text('添加到列表'),
                ),
              ),
            ),
          ],
          // 常用端口列表 (模式2)
          if (_selectedMode == 2) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('选择常用端口'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedCommonPorts.length ==
                            PortParser.commonPortDefinitions.length) {
                          _selectedCommonPorts.clear();
                        } else {
                          _selectedCommonPorts.addAll(
                            PortParser.commonPortDefinitions
                                .map((e) => e.port),
                          );
                        }
                      });
                    },
                    child: Text(
                      _selectedCommonPorts.length ==
                              PortParser.commonPortDefinitions.length
                          ? '取消全选'
                          : '全选',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: PortParser.commonPortDefinitions.length,
                itemBuilder: (context, index) {
                  final def = PortParser.commonPortDefinitions[index];
                  final isSelected = _selectedCommonPorts.contains(def.port);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedCommonPorts.add(def.port);
                        } else {
                          _selectedCommonPorts.remove(def.port);
                        }
                      });
                    },
                    title: Text('${def.serviceName} (${def.port})'),
                    subtitle: Text(def.description),
                    secondary: CircleAvatar(
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.shade200,
                      child: Text(
                        '${def.port}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _selectedCommonPorts.isNotEmpty
                      ? _addCommonPorts
                      : null,
                  icon: const Icon(Icons.add),
                  label: Text(
                    '添加选中的端口 (${_selectedCommonPorts.length})',
                  ),
                ),
              ),
            ),
          ],
          if (_selectedMode != 2) ...[
            const Divider(),
            // 当前端口列表
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '已添加的端口 (${widget.scanState.portEntries.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (widget.scanState.portEntries.isNotEmpty)
                    TextButton(
                      onPressed: () => widget.scanState.clearPortEntries(),
                      child: const Text('清空全部'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.scanState,
                builder: (context, _) {
                  if (widget.scanState.portEntries.isEmpty) {
                    return const Center(
                      child: Text('暂无端口，请添加'),
                    );
                  }
                  return ListView.builder(
                    itemCount: widget.scanState.portEntries.length,
                    itemBuilder: (context, index) {
                      final entry = widget.scanState.portEntries[index];
                      return ListTile(
                        leading: const Icon(Icons.dns),
                        title: Text('端口 ${entry.port}'),
                        subtitle: Text(entry.source),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              widget.scanState.removePortEntry(index),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addPort() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _error = '请输入端口');
      return;
    }

    List<PortEntry> entries;
    switch (_selectedMode) {
      case 0:
        entries = PortParser.parseDirectPort(input);
        if (entries.isEmpty) {
          setState(() => _error = '无效端口号 (1-65535)');
          return;
        }
        break;
      case 1:
        entries = PortParser.parsePortRange(input);
        if (entries.isEmpty) {
          setState(() => _error = '无效端口范围格式，请使用如 1:1024');
          return;
        }
        break;
      default:
        return;
    }

    widget.scanState.addPortEntries(entries);
    _controller.clear();
    setState(() => _error = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加 ${entries.length} 个端口')),
    );
  }

  void _addCommonPorts() {
    final entries = PortParser.getCommonPorts()
        .where((e) => _selectedCommonPorts.contains(e.port))
        .toList();

    widget.scanState.addPortEntries(entries);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加 ${entries.length} 个常用端口')),
    );
  }
}

class _PortMode {
  final String label;
  final String hint;
  final IconData icon;
  const _PortMode(this.label, this.hint, this.icon);
}