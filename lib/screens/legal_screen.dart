import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String type;

  const LegalScreen({super.key, required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          type == 'terms' ? _terms : _privacy,
          style: TextStyle(
            fontSize: 14,
            height: 1.8,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

const _terms = '''CentPlay 이용약관

제1조 (목적)
본 약관은 CentPlay(이하 "서비스")를 이용함에 있어 이용자와 서비스 제공자 간의 권리, 의무 및 책임사항을 규정합니다.

제2조 (서비스 내용)
1. 서비스는 다양한 미니게임을 WebView 기반으로 제공하는 게임 허브 플랫폼입니다.
2. 이용자는 게임 플레이, 찜하기, 공유, 친구 추가, 채팅 등의 기능을 이용할 수 있습니다.
3. 일부 게임은 외부 제공자의 콘텐츠를 포함하며, 해당 콘텐츠의 저작권은 원저작자에게 있습니다.

제3조 (계정)
1. 이용자는 Google 계정 또는 게스트 모드로 서비스를 이용할 수 있습니다.
2. 계정 정보는 Firebase Authentication을 통해 안전하게 관리됩니다.

제4조 (데이터)
1. 이용자의 게임 기록, 찜 목록, 채팅 내역은 Firebase Firestore에 저장됩니다.
2. 계정 삭제 시 관련 데이터가 함께 삭제됩니다.

제5조 (면책)
1. 본 서비스는 포트폴리오 데모 목적으로 제작되었습니다.
2. 상점 내 아이템은 실제 결제가 이루어지지 않습니다.
3. 서비스 제공자는 외부 게임 콘텐츠의 가용성을 보장하지 않습니다.

최종 업데이트: 2026년 4월''';

const _privacy = '''CentPlay 개인정보 처리방침

1. 수집하는 개인정보
- Google 계정 정보 (이름, 이메일, 프로필 사진)
- 게임 플레이 기록 및 찜 목록
- 채팅 메시지 내용
- FCM 푸시 토큰

2. 수집 목적
- 서비스 제공 및 사용자 인증
- 찜 목록, 친구 목록 등 개인화 기능 제공
- 푸시 알림 발송
- 서비스 개선 및 통계 분석

3. 보관 기간
- 계정 유지 기간 동안 보관
- 계정 삭제 요청 시 즉시 파기

4. 제3자 제공
- Firebase (Google) — 인증, 데이터 저장, 푸시 알림
- 이외 제3자에게 개인정보를 제공하지 않습니다.

5. 이용자의 권리
- 언제든지 계정을 삭제하고 데이터 삭제를 요청할 수 있습니다.
- 프로필 화면에서 로그아웃 및 계정 관리가 가능합니다.

6. 연락처
- 이메일: qlqjsdmsz8@gmail.com

최종 업데이트: 2026년 4월''';
