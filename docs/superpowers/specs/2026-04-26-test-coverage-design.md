# Test Coverage Spec

## Goal
기존 ~5% 커버리지를 핵심 레이어 중심으로 보강. 포트폴리오 대응.

## Test Strategy

### Fake > Mock 원칙
- **Platform Channel**: `TestDefaultBinaryMessengerBinding`으로 MethodChannel/EventChannel fake
- **Firebase Firestore**: `fake_cloud_firestore` (인메모리 Firestore, 실 쿼리 로직 검증)
- **Firebase Auth**: `firebase_auth_mocks` (인메모리 auth state)
- **Riverpod Provider**: `ProviderContainer.overrides`로 fake 서비스 주입
- 순수 mock (`when().thenReturn()`)은 최소한으로

### Layer 1: Services

#### NativeVideoPlayerController
- `TestDefaultBinaryMessengerBinding`으로 MethodChannel handler 등록
- `create` → textureId 반환 검증
- 이벤트 스트림: initialized → isInitialized true, duration/size 설정
- 상태 전이: play → isPlaying, pause → !isPlaying, buffering → isBuffering, bufferingEnd → !isBuffering
- seek → position 변경
- completed → isCompleted
- error → error 메시지 설정
- dispose 순서: native dispose 먼저 → 스트림 정리
- 멀티 인스턴스: 다른 textureId 이벤트 무시

#### AuthService
- `firebase_auth_mocks`: signInAnonymously → user 생성, signOut → null
- signInWithGoogle: credential 반환 (mock GoogleSignIn)

#### FirestoreService
- `fake_cloud_firestore`: saveUserProfile → doc 존재 확인
- seedMDC: 중복 호출 시 덮어쓰지 않음 (idempotent)
- getFriends: 스트림 구독 → 데이터 변경 시 업데이트

#### GameBridgeService
- MethodChannel fake: sendCommand → 올바른 args 전달 확인
- triggerHaptic → pattern 전달 확인

### Layer 2: Providers

- `gamesProvider`: FakeFirestore에 게임 문서 추가 → provider가 Game 모델 리스트 반환
- `videosProvider`: 동일 패턴
- `favoritesProvider`: 즐겨찾기 추가/제거 → 상태 반영
- `themeProvider`: 모드 전환 → ThemeMode 변경

### Layer 3: Widgets

- `NativeVideoPlayer`: 로딩 → 플레이어 → 에러 상태별 위젯 렌더링 검증
- `VideoFeedScreen`: 3개 카드 렌더링 + 탭 시 Navigator push 확인
- `PrimaryButton` (기존 보강): error shake 애니메이션 트리거 확인

## Dependencies 추가
```yaml
dev_dependencies:
  fake_cloud_firestore: ^3.1.0
  firebase_auth_mocks: ^0.14.1
  mockito: ^5.4.4
  build_runner: ^2.4.13
```

## File Structure
```
test/
  services/
    native_video_player_controller_test.dart
    auth_service_test.dart
    firestore_service_test.dart
    game_bridge_service_test.dart
  providers/
    games_provider_test.dart
    videos_provider_test.dart
    favorites_provider_test.dart
    theme_provider_test.dart
  widgets/
    native_video_player_test.dart
    video_feed_screen_test.dart
  design_system/
    primary_button_test.dart  (기존 보강)
    async_data_view_test.dart (기존)
```
