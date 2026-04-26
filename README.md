# CentPlay

미니게임 허브 앱. Flutter + Firebase + WebView 기반.

슈퍼센트 Flutter 클라이언트 개발자 포지션 공고의 직무를 참고해 구현한 데모 프로젝트입니다.

## 데모

<p align="center">
  <img src="demo.gif" width="280" alt="CentPlay Demo">
</p>

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
├── design_system/        # Well-made UI 계약 컴포넌트 ★
│   ├── primary_button.dart    # debounce + in-flight + loading + error
│   ├── async_data_view.dart   # loading/error/empty/data 4상태 강제
│   └── app_snackbar.dart      # success/error/info 표준 토스트
├── models/               # Game, Video, Friend, ChatMessage
├── services/             # AuthService, FirestoreService, PushService
├── providers/            # Riverpod (auth, games, favorites, friends, theme)
├── screens/              # 12개 화면
├── widgets/              # GameCard, SectionHeader, Loading/Error/Empty
├── router.dart           # GoRouter + ShellRoute + auth guard
└── main.dart             # Firebase init + FCM background handler
```

## 품질 · 자동화 워크플로우

다른 포트폴리오가 "화면 구현" 을 보여준다면, 이 리포는 **"팀 투입 시 그대로 가져갈 수 있는 자동화 레이어"** 도 같이 커밋해 뒀다. 공고의 "수억 다운로드 라이브 서비스 · 안정성" 요구에 대응.

| 레이어 | 파일 | 무엇을 보장하나 |
|---|---|---|
| UI 계약 | `lib/design_system/primary_button.dart` | 결제/액션 버튼이 연타·중복 호출·loading 누락을 **자동 방어** |
| UI 계약 | `lib/design_system/async_data_view.dart` | 모든 화면이 loading · error + retry · empty · data 4상태를 일관 |
| UI 계약 | `lib/design_system/app_snackbar.dart` | 토스트 메시지 디자인·에러 재시도 액션 표준 |
| 테스트 | `test/design_system/*_test.dart` | 위 계약을 **widget test 로 lock** — debounce 빠지면 빌드 실패 |
| 정적 분석 | `analysis_options.yaml` | `avoid_print` / `use_build_context_synchronously` 에러 승격 |
| CI | `.github/workflows/pr.yml` | PR 마다 format · analyze · test · debug 빌드 자동 |
| 운영 | `.github/workflows/rollback.yml` | Remote Config flag 원격 off — **앱 재배포 없이 2분 내 롤백** |
| 리뷰 | `.github/CODEOWNERS` | 결제 · 인증 · CI 경로 변경 시 자동 리뷰어 태그 |
| 리뷰 | `.github/pull_request_template.md` | PR 마다 결제·시간·동시성 체크박스 강제 |

설계 의도 상세는 `obsidian/슈퍼센트 준비/공고대응_학습/testing-qa/` 에 문서화.

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
