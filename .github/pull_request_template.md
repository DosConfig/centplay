<!--
CentPlay PR 체크리스트.
공고대응_학습/testing-qa/03_static_analysis_and_gates.md §5 참고.

의도: 체크박스 자체가 "이거 생각했어?" 를 강제해서 실수 패턴을 줄인다.
특히 결제 · 시간 · 동시성 항목은 항상 보이도록 따로 배치.
-->

## 목적 (Why)
<!-- 무슨 문제를 풀고 왜 필요한가 -->

## 변경사항 (What)
<!-- 주요 변경 요약. Breaking change 있으면 명시. -->

## 테스트
- [ ] Unit / Widget test 추가 또는 갱신
- [ ] 수동 테스트한 시나리오:

## UI 변경이 있는 PR 인가요?
- [ ] 다크 모드 확인
- [ ] 다국어 (있는 경우) 확인
- [ ] **Raw ElevatedButton · ScaffoldMessenger 직접 호출 없음** (design_system 모듈 사용)
- [ ] Loading / Error / Empty 상태 커버

## 결제 · 시간 · 동시성 관련인가요?
<!-- 공고대응_학습의 backend-collab · iap 내용을 PR 에서도 체크 -->
- [ ] Idempotency Key (또는 `transactionId` 로 서버 멱등) 확인
- [ ] 시간값은 `DateTime.now().toUtc().toIso8601String()` 로 UTC 송신
- [ ] 버튼 debounce · in-flight guard (PrimaryButton 사용) 확인
- [ ] Optimistic UI 쓴 경우 롤백 경로 있음
- [ ] IAP 의 경우 `autoConsume: false` · 서버 검증 후 `completePurchase` 순서 확인

## 배포 · 롤백
- [ ] 신규 기능이면 Remote Config flag 뒤에 배치했음
- [ ] DB 스키마 변경 있으면 마이그레이션 / 하위 호환 설계 확인
- [ ] 이전 버전으로 롤백 시 데이터 꼬임 없는지

## 스크린샷 / 로그 / 관련 이슈
<!-- UI 변경 스크린샷 · 재현 로그 · Jira/Linear 링크 -->
