import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 네이티브 AVPlayer/ExoPlayer를 플랫폼 채널로 제어하는 컨트롤러.
///
/// video_player 패키지 없이 직접 구현.
/// textureId 기반 멀티 인스턴스 — 여러 플레이어 동시 운용 가능.
class NativeVideoPlayerController {
  NativeVideoPlayerController({required this.url});

  final String url;

  static const _method = MethodChannel('com.centplay/video_player');
  static const _events = EventChannel('com.centplay/video_player/events');

  /// 공유 EventChannel 스트림 — 모든 인스턴스가 같은 스트림을 listen.
  static Stream<dynamic>? _sharedStream;

  /// 테스트용: 공유 스트림 리셋.
  @visibleForTesting
  static void resetSharedStream() => _sharedStream = null;

  int? _textureId;
  int get textureId => _textureId!;
  bool get isInitialized => _textureId != null && _duration > Duration.zero;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  Duration _position = Duration.zero;
  Duration get position => _position;

  int _width = 0;
  int _height = 0;
  double get aspectRatio =>
      _width > 0 && _height > 0 ? _width / _height : 16 / 9;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isBuffering = false;
  bool get isBuffering => _isBuffering;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  String? _error;
  String? get error => _error;

  List<int> _availableBitrates = [];
  List<int> get availableBitrates => _availableBitrates;

  int _currentMaxBitrate = 0;
  int get currentMaxBitrate => _currentMaxBitrate;

  StreamSubscription? _eventSub;
  final _stateController = StreamController<void>.broadcast();
  final _readyCompleter = Completer<void>();

  Stream<void> get onStateChanged => _stateController.stream;

  Future<void> initialize() async {
    // 공유 스트림 (첫 인스턴스가 생성, 이후 재사용)
    _sharedStream ??= _events.receiveBroadcastStream().asBroadcastStream();
    _eventSub = _sharedStream!.listen(_handleEvent);

    final result = await _method.invokeMapMethod<String, dynamic>(
      'create',
      {'url': url},
    );
    _textureId = result!['textureId'] as int;
    _stateController.add(null);

    await _readyCompleter.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;
    final map = Map<String, dynamic>.from(event);

    // 멀티 인스턴스: 자기 textureId 이벤트만 처리
    final eventTid = map['textureId'];
    if (_textureId != null && eventTid != null && eventTid != _textureId) return;

    final type = map['event'] as String;

    switch (type) {
      case 'initialized':
        _duration = Duration(milliseconds: map['duration'] as int);
        _width = map['width'] as int;
        _height = map['height'] as int;
        if (!_readyCompleter.isCompleted) _readyCompleter.complete();
        unawaited(_fetchBitrates());

      case 'playing':
        _isPlaying = true;
        _isBuffering = false;
        _isCompleted = false;

      case 'paused':
        _isPlaying = false;

      case 'buffering':
        _isBuffering = true;

      case 'bufferingEnd':
        _isBuffering = false;

      case 'position':
        _position = Duration(milliseconds: map['position'] as int);

      case 'completed':
        _isCompleted = true;
        _isPlaying = false;

      case 'error':
        _error = map['message'] as String?;
    }

    _stateController.add(null);
  }

  Map<String, dynamic> _args([Map<String, dynamic>? extra]) {
    final map = <String, dynamic>{'textureId': _textureId};
    if (extra != null) map.addAll(extra);
    return map;
  }

  Future<void> play() => _method.invokeMethod('play', _args());

  Future<void> pause() => _method.invokeMethod('pause', _args());

  Future<void> seekTo(Duration position) =>
      _method.invokeMethod('seekTo', _args({'position': position.inMilliseconds}));

  Future<void> setPlaybackSpeed(double speed) =>
      _method.invokeMethod('setPlaybackSpeed', _args({'speed': speed}));

  Future<void> setMaxBitrate(int bitrate) async {
    _currentMaxBitrate = bitrate;
    await _method.invokeMethod('setMaxBitrate', _args({'bitrate': bitrate}));
    _stateController.add(null);
  }

  Future<void> _fetchBitrates() async {
    final result = await _method.invokeListMethod<int>(
        'getAvailableBitrates', _args());
    if (result != null && result.isNotEmpty) {
      _availableBitrates = result;
      _stateController.add(null);
    }
  }

  Future<void> dispose() async {
    await _method.invokeMethod('dispose', _args());
    await _eventSub?.cancel();
    await _stateController.close();
  }
}
