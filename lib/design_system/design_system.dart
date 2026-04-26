// lib/design_system/design_system.dart
//
// 디자인 시스템 barrel export.
//
// ## 사용 원칙
// - 화면에서 버튼 · 에러 상태 · 토스트를 만들 때는 이 모듈만 import.
// - Raw 위젯 (ElevatedButton · ScaffoldMessenger 등) 직접 사용 금지.
// - 새 공용 컴포넌트 추가 시 여기에 export 추가.
//
// ## 왜 이 폴더가 있는가
// - 공고대응_학습/testing-qa/04_ui_quality_contracts.md 참고
// - Well-made UI 5계약 (debounce · loading · disabled · error · retry) 을
//   개별 화면이 아닌 **컴포넌트 레이어** 에 박아두는 아키텍처.

export 'app_snackbar.dart';
export 'async_data_view.dart';
export 'primary_button.dart';
