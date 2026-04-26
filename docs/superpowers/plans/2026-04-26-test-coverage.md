# Test Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 핵심 서비스/프로바이더/위젯 테스트 추가로 커버리지 ~5% → 실질적 수준으로 보강

**Architecture:** 서비스 레이어에 생성자 의존성 주입 추가 → fake/mock 가능하게. Platform channel은 TestDefaultBinaryMessengerBinding으로 fake. Firestore는 fake_cloud_firestore. Provider는 ProviderContainer.overrides.

**Tech Stack:** flutter_test, fake_cloud_firestore, firebase_auth_mocks, TestDefaultBinaryMessengerBinding

---

### Task 1: 테스트 의존성 추가 + 서비스 DI 리팩터링

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/services/auth_service.dart`
- Modify: `lib/services/firestore_service.dart`

- [ ] **Step 1: pubspec.yaml에 테스트 의존성 추가**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  fake_cloud_firestore: ^3.1.0
  firebase_auth_mocks: ^0.14.1
```

- [ ] **Step 2: flutter pub get 실행**

Run: `flutter pub get`

- [ ] **Step 3: AuthService에 DI 추가**

`lib/services/auth_service.dart`에서 생성자를 수정하여 테스트 시 fake 주입 가능하게:

```dart
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  // ... 나머지 동일
```

- [ ] **Step 4: FirestoreService에 DI 추가**

`lib/services/firestore_service.dart`에서:

```dart
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  // ... 나머지 동일
```

- [ ] **Step 5: 기존 테스트 통과 확인**

Run: `flutter test`
Expected: 기존 3개 테스트 PASS

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/auth_service.dart lib/services/firestore_service.dart
git commit -m "refactor: add DI to services for testability"
```

---

### Task 2: NativeVideoPlayerController 테스트

**Files:**
- Create: `test/services/native_video_player_controller_test.dart`

- [ ] **Step 1: 테스트 파일 생성 — 초기화 테스트**

```dart
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

    // MethodChannel fake
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

    // EventChannel fake
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

    controller = NativeVideoPlayerController(url: 'https://example.com/test.m3u8');
  });

  tearDown(() async {
    // Reset channel handlers
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
    eventStreamController.close();
  });

  group('initialize', () {
    test('create 호출 후 textureId 설정', () async {
      // initialized 이벤트를 비동기로 보냄
      Future.delayed(const Duration(milliseconds: 50), () {
        eventStreamController.add({
          'event': 'initialized',
          'textureId': 42,
          'duration': 30000,
          'width': 1920,
          'height': 1080,
        });
      });

      await controller.initialize();

      expect(controller.textureId, 42);
      expect(controller.isInitialized, true);
      expect(controller.duration, const Duration(seconds: 30));
      expect(controller.aspectRatio, 1920 / 1080);
      expect(methodCalls.first.method, 'create');
    });
  });

  group('state transitions', () {
    setUp(() async {
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
    });

    test('play → isPlaying true', () async {
      eventStreamController.add({'event': 'playing', 'textureId': 42});
      await Future.delayed(Duration.zero);

      expect(controller.isPlaying, true);
      expect(controller.isBuffering, false);
    });

    test('pause → isPlaying false', () async {
      eventStreamController.add({'event': 'playing', 'textureId': 42});
      await Future.delayed(Duration.zero);
      eventStreamController.add({'event': 'paused', 'textureId': 42});
      await Future.delayed(Duration.zero);

      expect(controller.isPlaying, false);
    });

    test('buffering → isBuffering true, bufferingEnd → false', () async {
      eventStreamController.add({'event': 'buffering', 'textureId': 42});
      await Future.delayed(Duration.zero);
      expect(controller.isBuffering, true);

      eventStreamController.add({'event': 'bufferingEnd', 'textureId': 42});
      await Future.delayed(Duration.zero);
      expect(controller.isBuffering, false);
    });

    test('position 업데이트', () async {
      eventStreamController.add({'event': 'position', 'textureId': 42, 'position': 5000});
      await Future.delayed(Duration.zero);

      expect(controller.position, const Duration(seconds: 5));
    });

    test('completed → isCompleted true, isPlaying false', () async {
      eventStreamController.add({'event': 'playing', 'textureId': 42});
      await Future.delayed(Duration.zero);
      eventStreamController.add({'event': 'completed', 'textureId': 42});
      await Future.delayed(Duration.zero);

      expect(controller.isCompleted, true);
      expect(controller.isPlaying, false);
    });

    test('error → error 메시지 설정', () async {
      eventStreamController.add({
        'event': 'error',
        'textureId': 42,
        'message': 'Network error',
      });
      await Future.delayed(Duration.zero);

      expect(controller.error, 'Network error');
    });

    test('다른 textureId 이벤트 무시', () async {
      eventStreamController.add({'event': 'playing', 'textureId': 999});
      await Future.delayed(Duration.zero);

      expect(controller.isPlaying, false);
    });
  });

  group('commands', () {
    setUp(() async {
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
```

- [ ] **Step 2: 테스트 실행**

Run: `flutter test test/services/native_video_player_controller_test.dart`
Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add test/services/native_video_player_controller_test.dart
git commit -m "test: add NativeVideoPlayerController unit tests"
```

---

### Task 3: GameBridgeService 테스트

**Files:**
- Create: `test/services/game_bridge_service_test.dart`

- [ ] **Step 1: 테스트 파일 생성**

```dart
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

  test('setHardwareAcceleration → setWebViewConfig', () async {
    final service = GameBridgeService();
    await service.setHardwareAcceleration(true);

    expect(calls.last.method, 'setWebViewConfig');
    expect(calls.last.arguments['hardwareAccelerated'], true);
  });
}
```

- [ ] **Step 2: 테스트 실행**

Run: `flutter test test/services/game_bridge_service_test.dart`
Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add test/services/game_bridge_service_test.dart
git commit -m "test: add GameBridgeService unit tests"
```

---

### Task 4: FirestoreService 테스트 (fake_cloud_firestore)

**Files:**
- Create: `test/services/firestore_service_test.dart`

- [ ] **Step 1: 테스트 파일 생성**

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centplay/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: fakeFirestore);
  });

  group('saveUserProfile', () {
    test('새 프로필 저장', () async {
      await service.saveUserProfile('uid1', 'TestUser', 'test@test.com', null);

      final doc = await fakeFirestore.collection('users').doc('uid1').get();
      expect(doc.exists, true);
      expect(doc.data()!['displayName'], 'TestUser');
      expect(doc.data()!['email'], 'test@test.com');
      expect(doc.data()!['photoUrl'], '');
    });

    test('기존 프로필 merge 업데이트', () async {
      await service.saveUserProfile('uid1', 'Old', 'old@test.com', null);
      await service.saveUserProfile('uid1', 'New', 'new@test.com', 'http://photo.jpg');

      final doc = await fakeFirestore.collection('users').doc('uid1').get();
      expect(doc.data()!['displayName'], 'New');
      expect(doc.data()!['photoUrl'], 'http://photo.jpg');
    });
  });

  group('favorites', () {
    test('즐겨찾기 추가 후 목록에 포함', () async {
      await fakeFirestore
          .collection('users').doc('uid1')
          .collection('favorites').doc('game1')
          .set({'addedAt': DateTime.now()});

      final favorites = await service.getFavorites('uid1').first;
      expect(favorites, contains('game1'));
    });

    test('toggleFavorite — 없으면 추가, 있으면 제거', () async {
      // 추가
      await service.toggleFavorite('uid1', 'game1');
      var favs = await service.getFavorites('uid1').first;
      expect(favs, contains('game1'));

      // 제거
      await service.toggleFavorite('uid1', 'game1');
      favs = await service.getFavorites('uid1').first;
      expect(favs, isNot(contains('game1')));
    });
  });

  group('games', () {
    test('getGames → Firestore 문서를 Game 모델로 변환', () async {
      await fakeFirestore.collection('games').doc('g1').set({
        'title': 'Test Game',
        'description': 'A test',
        'thumbnailUrl': 'http://thumb.jpg',
        'webglUrl': 'http://game.html',
        'trailerUrl': '',
        'rank': 1,
        'rating': 4.5,
        'isRecommended': true,
        'category': 'Action',
      });

      final games = await service.getGames().first;
      expect(games.length, 1);
      expect(games.first.title, 'Test Game');
      expect(games.first.rating, 4.5);
      expect(games.first.isRecommended, true);
    });
  });

  group('friends', () {
    test('addFriend → 양방향 추가', () async {
      // user 프로필 미리 생성
      await fakeFirestore.collection('users').doc('uid2').set({
        'displayName': 'Friend',
        'email': 'friend@test.com',
        'photoUrl': '',
      });
      await fakeFirestore.collection('users').doc('uid1').set({
        'displayName': 'Me',
        'email': 'me@test.com',
        'photoUrl': '',
      });

      await service.addFriend('uid1', 'uid2');

      final myFriends = await fakeFirestore
          .collection('users').doc('uid1')
          .collection('friends').get();
      final theirFriends = await fakeFirestore
          .collection('users').doc('uid2')
          .collection('friends').get();

      expect(myFriends.docs.length, 1);
      expect(theirFriends.docs.length, 1);
    });

    test('removeFriend → 양방향 제거', () async {
      await fakeFirestore.collection('users').doc('uid2').set({
        'displayName': 'Friend', 'email': 'f@t.com', 'photoUrl': '',
      });
      await fakeFirestore.collection('users').doc('uid1').set({
        'displayName': 'Me', 'email': 'm@t.com', 'photoUrl': '',
      });
      await service.addFriend('uid1', 'uid2');
      await service.removeFriend('uid1', 'uid2');

      final myFriends = await fakeFirestore
          .collection('users').doc('uid1')
          .collection('friends').get();
      expect(myFriends.docs, isEmpty);
    });
  });

  group('seedMDC', () {
    test('idempotent — 두 번 호출해도 덮어쓰지 않음', () async {
      await service.seedMDC();
      final firstCall = await fakeFirestore.collection('games').doc('centplay-demo').get();
      final firstTitle = firstCall.data()!['title'];

      await service.seedMDC();
      final secondCall = await fakeFirestore.collection('games').doc('centplay-demo').get();

      expect(secondCall.data()!['title'], firstTitle);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행**

Run: `flutter test test/services/firestore_service_test.dart`
Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add test/services/firestore_service_test.dart
git commit -m "test: add FirestoreService tests with fake_cloud_firestore"
```

---

### Task 5: Provider 테스트

**Files:**
- Create: `test/providers/providers_test.dart`

- [ ] **Step 1: 테스트 파일 생성**

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centplay/providers/games_provider.dart';
import 'package:centplay/providers/favorites_provider.dart';
import 'package:centplay/providers/theme_provider.dart';
import 'package:centplay/services/firestore_service.dart';
import 'package:flutter/material.dart';

void main() {
  group('themeModeProvider', () {
    test('기본값 dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('light로 전환', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });

  group('gamesProvider', () {
    test('Firestore 문서 → Game 리스트', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('games').doc('g1').set({
        'title': 'Test Game',
        'description': 'desc',
        'thumbnailUrl': '',
        'webglUrl': '',
        'trailerUrl': '',
        'rank': 1,
        'rating': 4.0,
        'isRecommended': false,
        'category': 'Puzzle',
      });

      final container = ProviderContainer(
        overrides: [
          firestoreServiceProvider.overrideWithValue(
            FirestoreService(firestore: fakeFirestore),
          ),
        ],
      );
      addTearDown(container.dispose);

      // StreamProvider는 비동기이므로 첫 데이터 대기
      await container.read(gamesProvider.future);
      final games = container.read(gamesProvider).value!;

      expect(games.length, 1);
      expect(games.first.title, 'Test Game');
      expect(games.first.category, 'Puzzle');
    });

    test('gameByIdProvider → ID로 검색', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('games').doc('g1').set({
        'title': 'Found',
        'description': '',
        'thumbnailUrl': '',
        'webglUrl': '',
        'trailerUrl': '',
        'rank': 1,
        'rating': 3.0,
        'isRecommended': false,
        'category': 'Action',
      });

      final container = ProviderContainer(
        overrides: [
          firestoreServiceProvider.overrideWithValue(
            FirestoreService(firestore: fakeFirestore),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gamesProvider.future);
      final game = container.read(gameByIdProvider('g1'));

      expect(game, isNotNull);
      expect(game!.title, 'Found');
    });

    test('recommendedGamesProvider → isRecommended 필터', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final gameData = {
        'description': '',
        'thumbnailUrl': '',
        'webglUrl': '',
        'trailerUrl': '',
        'rank': 1,
        'rating': 4.0,
        'category': 'Action',
      };
      await fakeFirestore.collection('games').doc('g1').set({
        ...gameData,
        'title': 'Recommended',
        'isRecommended': true,
      });
      await fakeFirestore.collection('games').doc('g2').set({
        ...gameData,
        'title': 'Not Recommended',
        'isRecommended': false,
      });

      final container = ProviderContainer(
        overrides: [
          firestoreServiceProvider.overrideWithValue(
            FirestoreService(firestore: fakeFirestore),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gamesProvider.future);
      final recommended = container.read(recommendedGamesProvider).value!;

      expect(recommended.length, 1);
      expect(recommended.first.title, 'Recommended');
    });
  });
}
```

- [ ] **Step 2: 테스트 실행**

Run: `flutter test test/providers/providers_test.dart`
Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add test/providers/providers_test.dart
git commit -m "test: add provider tests with ProviderContainer overrides"
```

---

### Task 6: Widget 테스트 — VideoFeedScreen

**Files:**
- Create: `test/widgets/video_feed_screen_test.dart`

- [ ] **Step 1: 테스트 파일 생성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centplay/screens/video_feed_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('3개 비디오 카드 렌더링', (tester) async {
    await tester.pumpWidget(wrap(const VideoFeedScreen()));

    expect(find.text('HLS 어댑티브 스트리밍'), findsOneWidget);
    expect(find.text('Apple 기본 스트림'), findsOneWidget);
    expect(find.text('mp4 단일 파일 (비교군)'), findsOneWidget);
  });

  testWidgets('HLS 배지 표시', (tester) async {
    await tester.pumpWidget(wrap(const VideoFeedScreen()));

    expect(find.text('HLS'), findsNWidgets(2));
    expect(find.text('MP4'), findsOneWidget);
  });

  testWidgets('카드 탭 → Navigator push', (tester) async {
    await tester.pumpWidget(wrap(const VideoFeedScreen()));
    await tester.tap(find.text('HLS 어댑티브 스트리밍'));
    await tester.pumpAndSettle();

    // VideoPlayerScreen으로 이동 확인
    expect(find.text('플랫폼 채널 기반 네이티브 플레이어'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트 실행**

Run: `flutter test test/widgets/video_feed_screen_test.dart`
Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add test/widgets/video_feed_screen_test.dart
git commit -m "test: add VideoFeedScreen widget tests"
```

---

### Task 7: 프로젝트 분석 이슈 수정

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/screens/webview_screen.dart`
- Modify: `lib/main.dart`
- Delete: `test/widget_test.dart` (placeholder 제거)

- [ ] **Step 1: app.dart — BuildContext async gap 수정**

`lib/app.dart:32` 에서 async gap 이후 context 사용 부분을 수정:

```dart
// Before:
// ScaffoldMessenger.of(ctx)... (async gap 후)

// After: mounted check 추가 또는 navigator key 사용
if (ctx.mounted) {
  ScaffoldMessenger.of(ctx)...
}
```

- [ ] **Step 2: webview_screen.dart — 미사용 _gameState 제거**

`lib/screens/webview_screen.dart:28`의 `String _gameState = 'loading';` 필드와 관련 할당 제거.

- [ ] **Step 3: main.dart — seedMDC unawaited 처리**

```dart
import 'dart:async';
// ...
unawaited(FirestoreService().seedMDC());
```

- [ ] **Step 4: placeholder test 삭제**

```bash
rm test/widget_test.dart
```

- [ ] **Step 5: flutter analyze 통과 확인**

Run: `flutter analyze`
Expected: 0 errors

- [ ] **Step 6: 전체 테스트 통과 확인**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "fix: resolve project analysis issues (async gap, unused field, unawaited)"
```

---

## Summary

| Task | 테스트 수 | 대상 |
|------|-----------|------|
| Task 1 | 0 (인프라) | DI 리팩터링 + 의존성 추가 |
| Task 2 | ~12 | NativeVideoPlayerController 상태 전이 |
| Task 3 | 5 | GameBridgeService 커맨드 |
| Task 4 | ~8 | FirestoreService CRUD |
| Task 5 | 5 | Provider override 테스트 |
| Task 6 | 3 | VideoFeedScreen 위젯 |
| Task 7 | 0 (버그픽스) | 프로젝트 분석 이슈 수정 |
