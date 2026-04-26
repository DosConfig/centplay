// lib/design_system/app_snackbar.dart
//
// # AppSnackbar — 표준화된 토스트 메시지
//
// ## 왜 필요한가
// - `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` 직접 호출은
//   디자인 일관성이 없고, 에러 시 재시도 버튼 누락이 잦다.
// - 이 헬퍼만 사용하도록 강제 (custom lint: no_raw_snackbar)
//
// ## API
// - `AppSnackbar.success(context, '저장되었습니다')`
// - `AppSnackbar.error(context, '네트워크 오류', onRetry: () => ref.refresh(...))`
// - `AppSnackbar.info(context, '새 버전이 있습니다')`
//
// ## 보장하는 것
// - 동시 snackbar 여러 개 쌓이지 않음 (clearSnackBars 먼저)
// - 종류별 색상 + 아이콘 일관
// - 에러 시 재시도 액션 자동

import 'package:flutter/material.dart';

enum _SnackbarKind { success, error, info }

class AppSnackbar {
  const AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, kind: _SnackbarKind.success);

  static void error(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) =>
      _show(
        context,
        message,
        kind: _SnackbarKind.error,
        action: onRetry != null
            ? SnackBarAction(
                label: '다시 시도',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      );

  static void info(BuildContext context, String message) =>
      _show(context, message, kind: _SnackbarKind.info);

  static void _show(
    BuildContext context,
    String message, {
    required _SnackbarKind kind,
    SnackBarAction? action,
  }) {
    final (bgColor, icon) = switch (kind) {
      _SnackbarKind.success => (Colors.green.shade700, Icons.check_circle),
      _SnackbarKind.error => (Colors.red.shade700, Icons.error_outline),
      _SnackbarKind.info => (Colors.blueGrey.shade700, Icons.info_outline),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          action: action,
          duration: kind == _SnackbarKind.error
              ? const Duration(seconds: 5)
              : const Duration(seconds: 3),
        ),
      );
  }
}
