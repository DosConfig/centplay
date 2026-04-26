// lib/design_system/primary_button.dart
//
// # PrimaryButton 계약 (Well-made 5 원칙)
//
// ## 보장하는 것
// - **Debouncing**: 300ms 이내 재탭은 무시 (빠른 연타 보호)
// - **In-flight guard**: Future 진행 중 재탭 무시 (race condition 방어)
// - **Loading 상태**: 진행 중 스피너 + disabled 자동
// - **Disabled 상태**: `onPressed: null` 이면 회색 처리
// - **Error 상태**: 실패 시 shake 애니메이션 + haptic feedback
//
// ## 사용 제약
// - `onPressed` 는 Future 반환 (동기 작업이면 async 감싸서 전달)
// - 에러 메시지를 유저에게 보이려면 호출부에서 try/catch + AppSnackbar.error
// - onPressed 가 null 이면 disabled
//
// ## 금지
// - `ElevatedButton` 직접 사용 금지 (custom lint rule: no_raw_elevated_button)
// - debounce/loading 을 개별 화면에서 구현 금지 — 여기서 전부 관리
//
// ## 면접 맥락
// - 수억 다운로드 라이브 서비스에서 결제 버튼 연타 · 중복 호출은 서버 · 돈 · CS 3중 타격
// - 사람이 매번 신경쓰면 빠지니까 컴포넌트 계약에 인코딩
// - 공고대응_학습/testing-qa/04_ui_quality_contracts.md 참고

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PrimaryButtonVariant {
  primary,
  secondary,
  danger,
}

class PrimaryButton extends StatefulWidget {
  /// 버튼 텍스트.
  final String label;

  /// 진행 상태를 관리할 비동기 핸들러.
  /// null 이면 disabled.
  final Future<void> Function()? onPressed;

  /// 왼쪽에 표시할 아이콘 (선택).
  final IconData? icon;

  /// 가로 꽉 채우기 여부.
  final bool expanded;

  /// 색상 variant.
  final PrimaryButtonVariant variant;

  /// Debounce 간격. 기본 300ms.
  final Duration debounce;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.variant = PrimaryButtonVariant.primary,
    this.debounce = const Duration(milliseconds: 300),
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _hasError = false;
  DateTime? _lastTap;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // 1) Debounce
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < widget.debounce) {
      return;
    }
    _lastTap = now;

    // 2) In-flight guard
    if (_loading) return;

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      await widget.onPressed!.call();
    } catch (_) {
      // 3) 에러 피드백 — shake + haptic + 색상 일시 변경
      if (mounted) {
        setState(() => _hasError = true);
        HapticFeedback.mediumImpact();
        _shake.forward(from: 0);
      }
      rethrow; // 상위에서 AppSnackbar.error 등 처리
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Color _backgroundColor(ThemeData theme) {
    if (_hasError) return theme.colorScheme.error;
    switch (widget.variant) {
      case PrimaryButtonVariant.primary:
        return theme.colorScheme.primary;
      case PrimaryButtonVariant.secondary:
        return theme.colorScheme.secondary;
      case PrimaryButtonVariant.danger:
        return theme.colorScheme.error;
    }
  }

  Color _foregroundColor(ThemeData theme) {
    if (_hasError) return theme.colorScheme.onError;
    switch (widget.variant) {
      case PrimaryButtonVariant.primary:
        return theme.colorScheme.onPrimary;
      case PrimaryButtonVariant.secondary:
        return theme.colorScheme.onSecondary;
      case PrimaryButtonVariant.danger:
        return theme.colorScheme.onError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null;

    final button = AnimatedBuilder(
      animation: _shake,
      builder: (_, child) {
        // shake: -10..+10 sine-like
        final v = _shake.value;
        final dx = v == 0 ? 0.0 : (v < 0.5 ? v * 20 : (1 - v) * 20) * ((v * 10).round().isEven ? 1 : -1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: ElevatedButton(
        key: Key('primary_button_${widget.label}'),
        onPressed: (isDisabled || _loading) ? null : _handleTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _backgroundColor(theme),
          foregroundColor: _foregroundColor(theme),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: _loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _foregroundColor(theme),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label),
                ],
              ),
      ),
    );

    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
