import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centplay/services/native_video_player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NativeVideoPlayerController controller;
  late List<MethodCall> methodCalls;
  late StreamController<Map<String, dynamic>> eventStreamController;

  setUp(() {
    methodCalls = [];
    eventStreamController = StreamController<Map<String, dynamic>>.broadcast();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.centplay/video_player'),
      (call) async {
        methodCalls.add(call);
        if (call.method == 'create') {
          return {'textureId': 42};
        }
        if (call.method == 'getAvailableBitrates') {
          return <int>[500000, 1000000, 2000000];
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      const EventChannel('com.centplay/video_player/events'),
      MockStreamHandler.inline(
        onListen: (args, sink) {
          eventStreamController.stream.listen((event) {
            sink.success(event);
          });
        },
      ),
    );

    controller =
        NativeVideoPlayerController(url: 'https://example.com/test.m3u8');
  });

  tearDown(() async {
    NativeVideoPlayerController.resetSharedStream();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.centplay/video_player'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      const EventChannel('com.centplay/video_player/events'),
      null,
    );
    await eventStreamController.close();
  });

  Future<void> initializeWithEvents() async {
    Future.delayed(const Duration(milliseconds: 10), () {
      eventStreamController.add({
        'event': 'initialized',
        'textureId': 42,
        'duration': 30000,
        'width': 1920,
        'height': 1080,
      });
    });
    await controller.initialize();
  }

  group('initialize', () {
    test('create 호출 후 textureId 설정', () async {
      await initializeWithEvents();

      expect(controller.textureId, 42);
      expect(controller.isInitialized, true);
      expect(controller.duration, const Duration(seconds: 30));
      expect(controller.aspectRatio, 1920 / 1080);
      expect(methodCalls.first.method, 'create');
    });
  });

  group('state transitions', () {
    setUp(() async {
      await initializeWithEvents();
    });

    test('play → isPlaying true', () async {
      eventStreamController.add({'event': 'playing', 'textureId': 42});
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.isPlaying, true);
      expect(controller.isBuffering, false);
    });

    test('pause → isPlaying false', () async {
      eventStreamController.add({'event': 'playing', 'textureId': 42});
      await Future.delayed(const Duration(milliseconds: 50));
      eventStreamController.add({'event': 'paused', 'textureId': 42});
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.isPlaying, false);
    });

    test('buffering → isBuffering true, bufferingEnd → false', () async {
      eventStreamController.add({'event': 'buffering', 'textureId': 42});
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.isBuffering, true);

      eventStreamController.add({'event': 'bufferingEnd', 'textureId': 42});
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.isBuffering, false);
    });

    test('position 업데이트', () async {
      eventStreamController
          .add({'event': 'position', 'textureId': 42, 'position': 5000});
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.position, const Duration(seconds: 5));
    });

    test('completed → isCompleted true, isPlaying false', () async {
      eventStreamController.add({'event': 'playing', 'textureId': 42});
      await Future.delayed(const Duration(milliseconds: 50));
      eventStreamController.add({'event': 'completed', 'textureId': 42});
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.isCompleted, true);
      expect(controller.isPlaying, false);
    });

    test('error → error 메시지 설정', () async {
      eventStreamController.add({
        'event': 'error',
        'textureId': 42,
        'message': 'Network error',
      });
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.error, 'Network error');
    });

    test('다른 textureId 이벤트 무시', () async {
      eventStreamController.add({'event': 'playing', 'textureId': 999});
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.isPlaying, false);
    });
  });

  group('commands', () {
    setUp(() async {
      await initializeWithEvents();
      methodCalls.clear();
    });

    test('play → MethodChannel 호출에 textureId 포함', () async {
      await controller.play();
      expect(methodCalls.last.method, 'play');
      expect(methodCalls.last.arguments['textureId'], 42);
    });

    test('seekTo → position 전달', () async {
      await controller.seekTo(const Duration(seconds: 10));
      expect(methodCalls.last.arguments['position'], 10000);
      expect(methodCalls.last.arguments['textureId'], 42);
    });

    test('setMaxBitrate → bitrate 전달 및 상태 업데이트', () async {
      await controller.setMaxBitrate(1000000);
      expect(controller.currentMaxBitrate, 1000000);
      expect(methodCalls.last.arguments['bitrate'], 1000000);
    });

    test('dispose → native dispose 호출', () async {
      await controller.dispose();
      expect(methodCalls.last.method, 'dispose');
    });
  });
}
