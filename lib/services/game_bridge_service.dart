import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Unity WebGL ↔ Flutter 네이티브 브릿지.
///
/// 패키지(webview_flutter)의 JS 채널은 문자열 단방향 전달만 가능하지만,
/// MethodChannel을 통한 네이티브 브릿지는:
/// - 양방향 통신 (Flutter → Game, Game → Flutter)
/// - 네이티브 햅틱 피드백 (게임 이벤트에 맞춘 진동 패턴)
/// - 네이티브 WebView 성능 제어 (하드웨어 가속, GPU 렌더링)
/// - 타입 안전한 데이터 전달 (Map, List 직렬화)
///
/// 패키지로 대체할 수 없는 이유:
/// webview_flutter의 JavaScriptChannel은 String만 받을 수 있고,
/// Flutter→WebView 방향은 runJavaScript()로 JS 코드를 직접 실행해야 함.
/// 네이티브 레벨에서 WebView의 evaluateJavaScript를 직접 호출하면
/// JS 실행 결과를 Future로 받을 수 있고, 에러 핸들링도 가능.
class GameBridgeService {
  static const _channel = MethodChannel('com.centplay/game_bridge');

  // 게임에서 Flutter로 오는 이벤트 콜백
  ValueChanged<GameEvent>? onGameEvent;

  // 싱글톤
  static final GameBridgeService _instance = GameBridgeService._();
  factory GameBridgeService() => _instance;

  GameBridgeService._() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// 네이티브에서 Flutter로 오는 호출 처리
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      // Unity → JS → Native → Flutter 경로로 전달되는 게임 이벤트
      case 'onGameEvent':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        final event = GameEvent.fromMap(data);
        debugPrint('[GameBridge] 이벤트 수신: ${event.type} ${event.data}');
        onGameEvent?.call(event);

        // 게임 이벤트에 따른 네이티브 햅틱 자동 트리거
        if (event.type == 'monster_killed') {
          await triggerHaptic(HapticPattern.impact);
        } else if (event.type == 'player_damaged') {
          await triggerHaptic(HapticPattern.warning);
        } else if (event.type == 'game_over') {
          await triggerHaptic(HapticPattern.failure);
        } else if (event.type == 'level_clear') {
          await triggerHaptic(HapticPattern.success);
        }
        return true;

      case 'onGameReady':
        debugPrint('[GameBridge] 게임 로드 완료');
        onGameEvent?.call(GameEvent(type: 'game_ready', data: {}));
        return true;

      default:
        throw MissingPluginException('Unknown method: ${call.method}');
    }
  }

  // ══════════════════════════════════════════
  // Flutter → Game 명령 (MethodChannel → Native → JS)
  // ══════════════════════════════════════════

  /// 게임 일시정지
  Future<void> pauseGame() async {
    await _channel.invokeMethod('sendToGame', {
      'command': 'pause',
    });
  }

  /// 게임 재개
  Future<void> resumeGame() async {
    await _channel.invokeMethod('sendToGame', {
      'command': 'resume',
    });
  }

  /// 게임 속도 변경 (Unity Time.timeScale)
  Future<void> setGameSpeed(double speed) async {
    await _channel.invokeMethod('sendToGame', {
      'command': 'setSpeed',
      'value': speed,
    });
  }

  /// 게임 상태 요청 (비동기 응답)
  Future<Map<String, dynamic>?> getGameState() async {
    final result = await _channel.invokeMethod<String>('getGameState');
    if (result != null) {
      return jsonDecode(result) as Map<String, dynamic>;
    }
    return null;
  }

  // ══════════════════════════════════════════
  // 네이티브 햅틱 피드백
  // 패키지(vibration 등)는 단순 on/off만 가능하지만,
  // 네이티브 API로는 패턴, 강도, 지속시간 세밀 제어 가능
  // ══════════════════════════════════════════

  /// 게임 이벤트에 맞춘 커스텀 햅틱 패턴
  Future<void> triggerHaptic(HapticPattern pattern) async {
    await _channel.invokeMethod('triggerHaptic', {
      'pattern': pattern.name,
    });
  }

  // ══════════════════════════════════════════
  // WebView 네이티브 성능 제어
  // ══════════════════════════════════════════

  /// 하드웨어 가속 설정 (Android 전용)
  Future<void> setHardwareAcceleration(bool enabled) async {
    await _channel.invokeMethod('setWebViewConfig', {
      'hardwareAccelerated': enabled,
    });
  }

  /// 리소스 해제
  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}

/// 게임에서 전달되는 이벤트
class GameEvent {
  final String type;
  final Map<String, dynamic> data;

  const GameEvent({required this.type, required this.data});

  factory GameEvent.fromMap(Map<String, dynamic> map) {
    return GameEvent(
      type: map['type'] as String? ?? 'unknown',
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
    );
  }
}

/// 네이티브 햅틱 패턴
enum HapticPattern {
  /// 몬스터 처치 — 짧고 강한 임팩트
  impact,

  /// 피격 — 더블 탭 경고
  warning,

  /// 게임 오버 — 긴 진동
  failure,

  /// 스테이지 클리어 — 성공 패턴
  success,
}
