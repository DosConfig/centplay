// lib/design_system/async_data_view.dart
//
// # AsyncDataView 계약
//
// ## 보장하는 것
// - **Loading**: 로딩 skeleton
// - **Error**: 에러 메시지 + 재시도 버튼 (PrimaryButton 사용)
// - **Empty**: 데이터는 왔지만 비어있을 때 별도 UI
// - **Data**: 정상 데이터
//
// ## 왜 필요한가
// - 화면마다 `if loading ... else if error ... else` 반복 → 누락 흔함
// - 특히 **"empty 상태 깜빡" + "retry 버튼 누락"** 이 가장 자주 빠짐
// - 이 래퍼가 강제하면 모든 화면이 일관
//
// ## 사용
// ```dart
// AsyncDataView<List<Game>>(
//   value: asyncValue,
//   onRetry: () => ref.refresh(gamesProvider.future),
//   isEmpty: (list) => list.isEmpty,
//   emptyBuilder: () => const _EmptyView(),
//   builder: (games) => GamesGrid(games: games),
// )
// ```

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'primary_button.dart';

class AsyncDataView<T> extends StatelessWidget {
  /// Riverpod `AsyncValue` — 외부에서 watch 한 값.
  final AsyncValue<T> value;

  /// 정상 데이터 렌더러.
  final Widget Function(T data) builder;

  /// 재시도 콜백. 에러/빈 상태 모두에서 CTA 로 사용 가능.
  final Future<void> Function() onRetry;

  /// empty 판정 함수 (옵션).
  final bool Function(T data)? isEmpty;

  /// empty 상태 렌더러 (옵션).
  final Widget Function()? emptyBuilder;

  /// 로딩 상태 렌더러 (옵션). 기본은 skeleton.
  final Widget Function()? loadingBuilder;

  /// 에러 메시지 human-ize 함수 (옵션).
  final String Function(Object error)? errorMapper;

  const AsyncDataView({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
    this.isEmpty,
    this.emptyBuilder,
    this.loadingBuilder,
    this.errorMapper,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loadingBuilder?.call() ?? const _LoadingSkeleton(),
      error: (e, _) => _AsyncErrorView(
        message: errorMapper?.call(e) ?? _humanize(e),
        onRetry: onRetry,
      ),
      data: (d) {
        if (isEmpty?.call(d) == true && emptyBuilder != null) {
          return emptyBuilder!.call();
        }
        return builder(d);
      },
    );
  }

  static String _humanize(Object e) {
    final text = e.toString();
    if (text.contains('SocketException') || text.contains('NetworkError')) {
      return '인터넷 연결을 확인해주세요.';
    }
    if (text.contains('TimeoutException')) {
      return '응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.';
    }
    if (text.contains('401') || text.contains('Unauthorized')) {
      return '로그인이 필요합니다.';
    }
    return '문제가 발생했습니다. 다시 시도해주세요.';
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _AsyncErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _AsyncErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: '다시 시도',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
