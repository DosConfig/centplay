# CentPlay

미니게임 허브 앱. Flutter + Firebase + WebView 기반.

슈퍼센트 Flutter 클라이언트 개발자 포지션 공고의 직무를 직접 구현한 데모 프로젝트입니다.

## 직무 매핑

| 공고 직무 | 구현 내용 |
|---------|---------|
| Flutter 크로스플랫폼 앱 | iOS + Android |
| 추천/랭킹/찜/공유/상점/프로필 | 각각 구현 |
| Firebase + 푸시 알림 | Auth(Google/Guest) + Firestore + FCM 딥링크 |
| WebView × 게임 실행 | 자체 호스팅 HTML5 게임 3종 + 외부 게임 2종 |
| Riverpod 상태 관리 | StreamProvider, Provider.family, StateProvider |
| 디자이너·백엔드 협업 UI/UX | 다크/라이트 테마, SBAggroOTF 커스텀 폰트 |

## 기능

- **홈**: 추천 게임(가로 스크롤) + 랭킹(세로 리스트) + 검색
- **게임 상세**: 썸네일, 설명, 게임플레이 트레일러, 찜/공유/상점, 비슷한 게임
- **게임 실행**: 풀스크린 WebView, 드래그 이동 가능한 나가기 버튼, iOS 스와이프백 차단
- **찜 목록**: Firestore 서브컬렉션 기반 실시간 동기화
- **친구**: 이메일 검색으로 추가, 상호 친구 등록
- **1:1 채팅**: Firestore 실시간 메시징
- **알림**: 읽음/미읽음 표시, 스와이프 삭제, 딥링크 라우팅
- **프로필**: 테마 전환(라이트/시스템/다크), 컨트롤러 설정, 이용약관, 개인정보
- **상점**: UI 데모
- **로그인**: Google Sign-In + 게스트(익명) 로그인
- **푸시**: FCM foreground 배너 + background/terminated 딥링크
- **게임패드**: Bluetooth 컨트롤러 입력 → WebView JS 이벤트 포워딩

## 아키텍처

```
lib/
├── core/theme.dart       # 디자인 시스템 (SBAggroOTF + 퍼플/블루 액센트)
├── models/               # Game, Video, Friend, ChatMessage
├── services/             # AuthService, FirestoreService, PushService
├── providers/            # Riverpod (auth, games, favorites, friends, theme)
├── screens/              # 12개 화면
├── widgets/              # GameCard, SectionHeader, Loading/Error/Empty
├── router.dart           # GoRouter + ShellRoute + auth guard
└── main.dart             # Firebase init + FCM background handler
```

## 게임

자체 호스팅 (`centplay-demo.web.app`):
| 게임 | 타입 |
|------|------|
| Brick Breaker | Canvas 2D, 터치 패들 |
| Snake | Canvas 2D, 스와이프 조종 |
| Flappy | Canvas 2D, 탭 플랩 |

## 실행

```bash
flutter pub get
flutter run
```

Firebase 설정:
```bash
flutterfire configure --project=centplay-demo
```

## 스택

Flutter 3.35 · Riverpod · GoRouter · Firebase (Auth/Firestore/FCM) · webview_flutter · video_player · share_plus · SBAggroOTF
