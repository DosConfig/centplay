# CentPlay 배포 가이드

## 환경 구성

### 개발 (Development)
```bash
flutter run                          # 로컬 디바이스/시뮬레이터
flutter run --dart-define=ENV=dev    # 환경변수 주입
```

### 스테이징 (Staging)
```bash
flutter build apk --dart-define=ENV=staging
flutter build ios --dart-define=ENV=staging
```

### 프로덕션 (Production)
```bash
flutter build appbundle --release    # Android (AAB for Play Store)
flutter build ios --release          # iOS (Archive → App Store Connect)
```

---

## Firebase 환경 분리

| 환경 | Firebase 프로젝트 | 용도 |
|------|------------------|------|
| dev | centplay-dev | 로컬 개발, 테스트 데이터 |
| staging | centplay-staging | QA, 내부 테스트 |
| production | centplay-demo | 라이브 서비스 |

환경별 Firebase 설정:
```bash
# 환경별 flutterfire 설정 생성
flutterfire configure --project=centplay-dev --out=lib/firebase_options_dev.dart
flutterfire configure --project=centplay-staging --out=lib/firebase_options_staging.dart
flutterfire configure --project=centplay-demo --out=lib/firebase_options.dart
```

main.dart에서 환경별 분기:
```dart
final env = const String.fromEnvironment('ENV', defaultValue: 'dev');
final options = switch (env) {
  'production' => DefaultFirebaseOptions.currentPlatform,
  'staging' => StagingFirebaseOptions.currentPlatform,
  _ => DevFirebaseOptions.currentPlatform,
};
await Firebase.initializeApp(options: options);
```

---

## 버전 관리

### 시맨틱 버전닝
```
MAJOR.MINOR.PATCH+BUILD
1.2.3+45
```
- MAJOR: 호환 안 되는 변경 (DB 마이그레이션 필요)
- MINOR: 신규 기능 추가
- PATCH: 버그 수정
- BUILD: CI 빌드 번호 (자동 증가)

### 강제 업데이트
```dart
// Firebase Remote Config
final minVersion = remoteConfig.getString('min_app_version');   // "1.2.0"
final currentVersion = packageInfo.version;                      // "1.1.5"

if (Version.parse(currentVersion) < Version.parse(minVersion)) {
  showForceUpdateDialog();
}
```

---

## 앱 배포

### Android (Play Store)
```bash
# 1. 서명 키 생성 (최초 1회)
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000

# 2. AAB 빌드
flutter build appbundle --release

# 3. Play Console 업로드
#    - 내부 테스트 → 비공개 테스트 → 프로덕션 단계적 배포
#    - 단계적 출시: 5% → 20% → 50% → 100%
```

### iOS (App Store)
```bash
# 1. Xcode Archive
flutter build ios --release
# Xcode → Product → Archive → Distribute App

# 2. App Store Connect
#    - TestFlight 내부 테스트 → 외부 테스트 → 앱 심사 제출
#    - 긴급 핫픽스: Expedited Review 요청 가능
```

### 게임 호스팅 (Firebase Hosting)
```bash
# HTML5 게임 배포
firebase deploy --only hosting --project centplay-demo
# URL: centplay-demo.web.app
```

---

## Feature Flag 운영

```dart
// Firebase Remote Config로 기능 플래그 관리
class FeatureFlags {
  static Future<void> init() async {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setDefaults({
      'enable_chat': true,
      'enable_gamepad': true,
      'enable_live_stream': false,
      'maintenance_mode': false,
    });
    await rc.fetchAndActivate();
  }

  static bool get isChatEnabled =>
    FirebaseRemoteConfig.instance.getBool('enable_chat');
}
```

긴급 상황 시:
1. Firebase Console → Remote Config → `maintenance_mode = true`
2. 앱에서 점검 화면 표시 (앱 업데이트 없이 즉시 적용)
3. 문제 해결 후 `maintenance_mode = false`

---

## Firestore 보안 규칙

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 게임 목록: 누구나 읽기 가능
    match /games/{gameId} {
      allow read: if true;
      allow write: if false; // 관리자만 Console에서 수정
    }

    // 유저 데이터: 본인만 읽기/쓰기
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // 찜 목록
      match /favorites/{gameId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      // 친구 목록
      match /friends/{friendId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // 채팅: 참여자만
    match /chatRooms/{roomId} {
      allow read: if request.auth != null &&
        request.auth.uid in resource.data.participants;

      match /messages/{msgId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
      }
    }
  }
}
```

---

## 롤백 절차

### 서버 사이드 (Firestore 규칙/Functions)
```bash
firebase deploy --only firestore:rules   # 규칙 롤백
firebase deploy --only functions          # Functions 롤백
```

### 앱 사이드
- Android: Play Console → 이전 버전 단계적 출시
- iOS: 롤백 불가 → 핫픽스 버전 빌드 후 Expedited Review
- 임시 대응: Remote Config로 문제 기능 비활성화
