import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TodoProvider>(context, listen: false);
    _urlController = TextEditingController(text: provider.serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testAndSave() async {
    final provider = Provider.of<TodoProvider>(context, listen: false);
    final url = _urlController.text.trim();

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final success = await provider.updateServerUrl(url);

    setState(() {
      _isTesting = false;
      _testSuccess = success;
      _testResult = success ? '✅ 连接服务器成功！' : '❌ 无法连接服务器，请检查地址或网络';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, size: 22),
          SizedBox(width: 8),
          Text('同步服务器配置'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PocketBase 服务端地址：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '如: http://192.168.1.100:8090',
                prefixIcon: Icon(Icons.cloud_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '提示：\n'
              '• 本机测试：http://127.0.0.1:8090\n'
              '• Android 模拟器：http://10.0.2.2:8090\n'
              '• Android 真机：填写电脑在局域网的 IP (如 http://192.168.x.x:8090)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 14),
              Text(
                _testResult!,
                style: TextStyle(
                  color: _testSuccess ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: _isTesting ? null : _testAndSave,
          icon: _isTesting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.sync, size: 16),
          label: const Text('测试并保存'),
        ),
      ],
    );
  }
}
