import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ControllerSettingsScreen extends StatefulWidget {
  const ControllerSettingsScreen({super.key});

  @override
  State<ControllerSettingsScreen> createState() =>
      _ControllerSettingsScreenState();
}

class _ControllerSettingsScreenState extends State<ControllerSettingsScreen> {
  final FocusNode _focusNode = FocusNode();
  String _lastInput = '입력 대기 중...';
  bool _detected = false;
  final List<_KeyBinding> _bindings = [
    _KeyBinding('이동 (위)', 'Arrow Up / W / D-Pad Up', Icons.arrow_upward),
    _KeyBinding('이동 (아래)', 'Arrow Down / S / D-Pad Down', Icons.arrow_downward),
    _KeyBinding('이동 (좌)', 'Arrow Left / A / D-Pad Left', Icons.arrow_back),
    _KeyBinding('이동 (우)', 'Arrow Right / D / D-Pad Right', Icons.arrow_forward),
    _KeyBinding('확인 / 점프', 'Space / Button A', Icons.check_circle_outline),
    _KeyBinding('취소 / 뒤로', 'Escape / Button B', Icons.cancel_outlined),
    _KeyBinding('시작', 'Enter / Start', Icons.play_arrow),
    _KeyBinding('메뉴', 'Escape / Select', Icons.menu),
  ];

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    setState(() {
      _detected = true;
      _lastInput = '감지: ${event.logicalKey.debugName ?? event.logicalKey.keyLabel}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('컨트롤러 설정')),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Connection status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _detected ? Icons.gamepad : Icons.gamepad_outlined,
                      size: 48,
                      color: _detected ? Colors.green : Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _detected ? '컨트롤러 연결됨' : '컨트롤러를 연결해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _detected ? Colors.green : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _lastInput,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '블루투스 컨트롤러 또는 키보드를 연결하고\n아무 버튼을 눌러 테스트하세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Key bindings
            Text('키 매핑',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _bindings.map((b) {
                  final isLast = b == _bindings.last;
                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              Icon(b.icon, size: 18, color: colorScheme.primary),
                        ),
                        title: Text(b.action,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(b.keys,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ),
                      if (!isLast) const Divider(height: 1, indent: 56),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Supported controllers
            Text('지원 컨트롤러',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _ControllerTile('Xbox Wireless Controller', 'Bluetooth'),
                  const Divider(height: 1, indent: 56),
                  _ControllerTile('DualSense (PS5)', 'Bluetooth'),
                  const Divider(height: 1, indent: 56),
                  _ControllerTile('DualShock 4 (PS4)', 'Bluetooth'),
                  const Divider(height: 1, indent: 56),
                  _ControllerTile('Nintendo Switch Pro', 'Bluetooth'),
                  const Divider(height: 1, indent: 56),
                  _ControllerTile('MFi Controllers', 'Bluetooth / USB'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControllerTile extends StatelessWidget {
  final String name;
  final String connection;
  const _ControllerTile(this.name, this.connection);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.sports_esports,
            size: 18, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(name, style: const TextStyle(fontSize: 14)),
      subtitle:
          Text(connection, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
    );
  }
}

class _KeyBinding {
  final String action;
  final String keys;
  final IconData icon;
  const _KeyBinding(this.action, this.keys, this.icon);
}
