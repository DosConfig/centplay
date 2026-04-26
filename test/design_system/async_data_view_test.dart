// test/design_system/async_data_view_test.dart
//
// AsyncDataView 의 4상태 (loading · error · empty · data) 계약 보장.

import 'package:centplay/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

Future<void> _noop() async {}

void main() {
  group('AsyncDataView 4-state contract', () {
    testWidgets('loading state shows progress indicator', (tester) async {
      await tester.pumpWidget(_wrap(
        AsyncDataView<List<String>>(
          value: const AsyncLoading(),
          onRetry: _noop,
          builder: (d) => Text('data: ${d.length}'),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
    });

    testWidgets('error state shows message and retry button', (tester) async {
      await tester.pumpWidget(_wrap(
        AsyncDataView<List<String>>(
          value: AsyncError<List<String>>(
            Exception('SocketException: failed'),
            StackTrace.empty,
          ),
          onRetry: _noop,
          builder: (d) => Text('data: ${d.length}'),
        ),
      ));

      // network 메시지로 humanize 됐는지
      expect(find.text('인터넷 연결을 확인해주세요.'), findsOneWidget);
      // 재시도 CTA
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
    });

    testWidgets('empty state uses emptyBuilder', (tester) async {
      await tester.pumpWidget(_wrap(
        AsyncDataView<List<String>>(
          value: const AsyncData([]),
          onRetry: _noop,
          isEmpty: (d) => d.isEmpty,
          emptyBuilder: () => const Text('비어있음'),
          builder: (d) => Text('data: ${d.length}'),
        ),
      ));

      expect(find.text('비어있음'), findsOneWidget);
      expect(find.text('data: 0'), findsNothing);
    });

    testWidgets('data state uses builder', (tester) async {
      await tester.pumpWidget(_wrap(
        AsyncDataView<List<String>>(
          value: const AsyncData(['a', 'b', 'c']),
          onRetry: _noop,
          isEmpty: (d) => d.isEmpty,
          emptyBuilder: () => const Text('비어있음'),
          builder: (d) => Text('data: ${d.length}'),
        ),
      ));

      expect(find.text('data: 3'), findsOneWidget);
      expect(find.text('비어있음'), findsNothing);
    });

    testWidgets('custom errorMapper overrides default humanize',
        (tester) async {
      await tester.pumpWidget(_wrap(
        AsyncDataView<List<String>>(
          value: AsyncError<List<String>>(
            'any',
            StackTrace.empty,
          ),
          onRetry: _noop,
          errorMapper: (_) => '커스텀 에러 메시지',
          builder: (d) => Text('data: ${d.length}'),
        ),
      ));

      expect(find.text('커스텀 에러 메시지'), findsOneWidget);
    });
  });
}
