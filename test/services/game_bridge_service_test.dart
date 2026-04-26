import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centplay/services/game_bridge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.centplay/game_bridge'),
      (call) async {
        calls.add(call);
        if (call.method == 'getGameState') {
          return '{"state":"playing","score":100}';
        }
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.centplay/game_bridge'),
      null,
    );
  });

  test('pauseGame → sendToGame with pause command', () async {
    final service = GameBridgeService();
    await service.pauseGame();

    expect(calls.last.method, 'sendToGame');
    expect(calls.last.arguments['command'], 'pause');
  });

  test('resumeGame → sendToGame with resume command', () async {
    final service = GameBridgeService();
    await service.resumeGame();

    expect(calls.last.method, 'sendToGame');
    expect(calls.last.arguments['command'], 'resume');
  });

  test('setGameSpeed → sendToGame with setSpeed and value', () async {
    final service = GameBridgeService();
    await service.setGameSpeed(2.0);

    expect(calls.last.method, 'sendToGame');
    expect(calls.last.arguments['command'], 'setSpeed');
    expect(calls.last.arguments['value'], 2.0);
  });

  test('triggerHaptic → correct pattern string', () async {
    final service = GameBridgeService();
    await service.triggerHaptic(HapticPattern.success);

    expect(calls.last.method, 'triggerHaptic');
    expect(calls.last.arguments['pattern'], 'success');
  });

  test('getGameState → JSON 파싱', () async {
    final service = GameBridgeService();
    final state = await service.getGameState();

    expect(state, isNotNull);
    expect(state!['state'], 'playing');
    expect(state['score'], 100);
  });

  test('setHardwareAcceleration → setWebViewConfig', () async {
    final service = GameBridgeService();
    await service.setHardwareAcceleration(true);

    expect(calls.last.method, 'setWebViewConfig');
    expect(calls.last.arguments['hardwareAccelerated'], true);
  });
}
