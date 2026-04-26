import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centplay/screens/video_feed_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('첫 두 비디오 카드 렌더링', (tester) async {
    await tester.pumpWidget(wrap(const VideoFeedScreen()));

    expect(find.text('HLS 어댑티브 스트리밍'), findsOneWidget);
    expect(find.text('Apple 기본 스트림'), findsOneWidget);
  });

  testWidgets('HLS 배지 표시', (tester) async {
    await tester.pumpWidget(wrap(const VideoFeedScreen()));

    expect(find.text('HLS'), findsNWidgets(2));
  });

  testWidgets('스크롤하면 mp4 카드 표시', (tester) async {
    await tester.pumpWidget(wrap(const VideoFeedScreen()));

    await tester.scrollUntilVisible(
      find.text('mp4 단일 파일 (비교군)'),
      200,
    );
    expect(find.text('mp4 단일 파일 (비교군)'), findsOneWidget);
    expect(find.text('MP4'), findsOneWidget);
  });

  testWidgets('subtitle 표시', (tester) async {
    await tester.pumpWidget(wrap(const VideoFeedScreen()));

    expect(
      find.text('6개 화질 · ABR 자동 전환 · 화질 수동 선택'),
      findsOneWidget,
    );
  });
}
