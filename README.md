# CentPlay

Flutter 기반 미니게임 허브 앱 데모 프로젝트입니다.

## 공고 직무 매핑

| 직무 | 구현 |
|------|------|
| Flutter 크로스플랫폼 앱 개발 | iOS + Android |
| 추천/랭킹/찜/공유/상점/프로필 | 전부 구현 |
| Firebase 연동 + 푸시 | Auth + Firestore + FCM |
| WebView x Unity WebGL | webview_flutter |
| Riverpod 상태 관리 | 전역 적용 (StreamProvider, Provider.family) |
| 영상 컨텐츠 | video_player |

## 아키텍처

```
lib/
├── models/          # Game, Video 데이터 모델
├── services/        # Firebase Auth, Firestore, FCM 서비스
├── providers/       # Riverpod 상태 관리
├── screens/         # 9개 화면 (Login, Home, GameDetail, WebView, Video, Favorites, Profile, Shop)
├── widgets/         # 재사용 위젯 (GameCard, Loading/Error/Empty 상태)
├── router.dart      # GoRouter (ShellRoute + auth redirect)
├── app.dart         # Material 3 테마
└── main.dart        # Firebase 초기화 + ProviderScope
```

- **상태 관리**: Riverpod (StreamProvider, Provider.family, auth redirect)
- **라우팅**: GoRouter (ShellRoute + 4탭 BottomNav + auth guard)
- **백엔드**: Firebase (Auth, Firestore, Cloud Messaging)
- **UI**: Material 3, Noto Sans KR

## 화면

| 화면 | 설명 |
|------|------|
| Login | Google 소셜 로그인 |
| Home | 추천 게임 (가로 스크롤) + 랭킹 (세로 리스트) |
| Game Detail | 썸네일, 설명, 게임 시작/찜/공유/상점 버튼, 비슷한 게임 |
| WebView | Unity WebGL 게임 실행 (풀스크린) |
| Video | 영상 컨텐츠 재생 (video_player) |
| Favorites | 찜한 게임 목록 (Firestore 서브컬렉션) |
| Profile | 유저 정보 + 통계 + 로그아웃 |
| Shop | 아이템 상점 (UI only) |

## 실행 방법

```bash
# 의존성 설치
flutter pub get

# 실행
flutter run
```

Firebase 프로젝트 설정이 필요합니다:
```bash
flutterfire configure --project=centplay-demo
```

## 기술 스택

Flutter 3.35 · Riverpod · GoRouter · Firebase (Auth/Firestore/FCM) · webview_flutter · video_player · share_plus · cached_network_image
