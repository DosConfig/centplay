import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/native_video_player_controller.dart';

/// 네이티브 플랫폼 채널 기반 비디오 플레이어 위젯.
///
/// Texture 위에 커스텀 오버레이(재생 컨트롤, 시크바, 화질 선택, 전체화면)를 직접 구현.
/// Chewie 없이 Flutter UI만으로 구성.
class NativeVideoPlayer extends StatefulWidget {
  const NativeVideoPlayer({
    super.key,
    required this.url,
    this.autoPlay = false,
    this.title,
  });

  final String url;
  final bool autoPlay;
  final String? title;

  @override
  State<NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

class _NativeVideoPlayerState extends State<NativeVideoPlayer> {
  NativeVideoPlayerController? _controller;
  StreamSubscription? _stateSub;
  String? _error;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _error = null);

    final controller = NativeVideoPlayerController(url: widget.url);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      _stateSub = controller.onStateChanged.listen((_) {
        if (mounted) setState(() {});
      });

      if (widget.autoPlay) {
        await controller.play();
      }

      setState(() {});
      _scheduleHideControls();
    } catch (e) {
      await controller.dispose();
      if (mounted) {
        setState(() => _error = '영상을 재생할 수 없습니다.\n$e');
      }
    }
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _enterFullscreen() {
    final c = _controller;
    if (c == null || !c.isInitialized) return;

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _FullscreenPlayer(
          controller: c,
          title: widget.title,
        ),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _stateSub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildError();
    if (_controller == null || !_controller!.isInitialized) return _buildLoading();
    return _buildPlayer();
  }

  Widget _buildLoading() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }

  Widget _buildError() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 36),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _initialize,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final c = _controller!;
    return AspectRatio(
      aspectRatio: c.aspectRatio,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Positioned.fill(child: Texture(textureId: c.textureId)),
            if (c.isBuffering)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            if (_showControls)
              _VideoOverlay(
                controller: c,
                title: widget.title,
                isFullscreen: false,
                onToggleControls: _scheduleHideControls,
                onFullscreen: _enterFullscreen,
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 전체화면 플레이어
// =============================================================================

class _FullscreenPlayer extends StatefulWidget {
  const _FullscreenPlayer({required this.controller, this.title});

  final NativeVideoPlayerController controller;
  final String? title;

  @override
  State<_FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<_FullscreenPlayer> {
  bool _showControls = true;
  Timer? _hideTimer;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    // 가로 모드 + 시스템 UI 숨김
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _stateSub = widget.controller.onStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
    _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _exitFullscreen() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _stateSub?.cancel();
    // 세로 모드 + 시스템 UI 복원
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // 비디오 — 화면 전체 채움
            Center(
              child: AspectRatio(
                aspectRatio: c.aspectRatio,
                child: Texture(textureId: c.textureId),
              ),
            ),
            if (c.isBuffering)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            if (_showControls)
              Positioned.fill(
                child: _VideoOverlay(
                  controller: c,
                  title: widget.title,
                  isFullscreen: true,
                  onToggleControls: _scheduleHideControls,
                  onFullscreen: _exitFullscreen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 공유 오버레이 (인라인 + 전체화면 공용)
// =============================================================================

class _VideoOverlay extends StatelessWidget {
  const _VideoOverlay({
    required this.controller,
    required this.title,
    required this.isFullscreen,
    required this.onToggleControls,
    required this.onFullscreen,
  });

  final NativeVideoPlayerController controller;
  final String? title;
  final bool isFullscreen;
  final VoidCallback onToggleControls;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent, Colors.black54],
        ),
      ),
      child: Column(
        children: [
          // 상단: 타이틀 + 화질
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (isFullscreen)
                  GestureDetector(
                    onTap: onFullscreen,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(),
                if (c.availableBitrates.isNotEmpty)
                  _BitrateButton(
                    currentBitrate: c.currentMaxBitrate,
                    availableBitrates: c.availableBitrates,
                    onSelected: (bitrate) => c.setMaxBitrate(bitrate),
                  ),
              ],
            ),
          ),

          // 중앙: 재생/일시정지
          Expanded(
            child: Center(
              child: _PlayPauseButton(
                isPlaying: c.isPlaying,
                isCompleted: c.isCompleted,
                onTap: () async {
                  if (c.isCompleted) {
                    await c.seekTo(Duration.zero);
                    await c.play();
                  } else if (c.isPlaying) {
                    await c.pause();
                  } else {
                    await c.play();
                  }
                  onToggleControls();
                },
              ),
            ),
          ),

          // 하단: 시크바 + 전체화면 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
            child: Row(
              children: [
                Text(
                  _formatDuration(c.position),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Theme.of(context).colorScheme.primary,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: c.duration.inMilliseconds > 0
                          ? (c.position.inMilliseconds / c.duration.inMilliseconds).clamp(0.0, 1.0)
                          : 0.0,
                      onChanged: (v) {
                        final target = Duration(
                          milliseconds: (v * c.duration.inMilliseconds).round(),
                        );
                        c.seekTo(target);
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(c.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 4),
                // 전체화면 토글
                GestureDetector(
                  onTap: onFullscreen,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.isCompleted,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = isCompleted
        ? Icons.replay
        : isPlaying
            ? Icons.pause_rounded
            : Icons.play_arrow_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}

class _BitrateButton extends StatelessWidget {
  const _BitrateButton({
    required this.currentBitrate,
    required this.availableBitrates,
    required this.onSelected,
  });

  final int currentBitrate;
  final List<int> availableBitrates;
  final ValueChanged<int> onSelected;

  String _label(int bitrate) {
    if (bitrate == 0) return '자동';
    final mbps = bitrate / 1000000;
    if (mbps >= 1) return '${mbps.toStringAsFixed(1)} Mbps';
    return '${(bitrate / 1000).round()} kbps';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A1A1A),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '화질 선택',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('자동', style: TextStyle(color: Colors.white)),
                  trailing: currentBitrate == 0
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    onSelected(0);
                    Navigator.pop(context);
                  },
                ),
                ...availableBitrates.reversed.map((br) => ListTile(
                      title: Text(_label(br), style: const TextStyle(color: Colors.white)),
                      trailing: currentBitrate == br
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        onSelected(br);
                        Navigator.pop(context);
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              _label(currentBitrate),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
