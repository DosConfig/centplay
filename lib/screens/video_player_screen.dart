import 'package:flutter/material.dart';

import '../widgets/native_video_player.dart';

/// 전체화면 비디오 플레이어 화면.
///
/// 영상 피드에서 탭하면 이 화면으로 전환.
class VideoPlayerScreen extends StatelessWidget {
  const VideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHls = url.contains('.m3u8');

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          // 플레이어
          NativeVideoPlayer(
            url: url,
            autoPlay: true,
            title: title,
          ),

          // 영상 정보
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  // 칩 행
                  Row(
                    children: [
                      _InfoChip(
                        label: isHls ? 'HLS 어댑티브' : 'MP4 단일 파일',
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        label: 'Platform Channel',
                        color: colorScheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '플랫폼 채널 기반 네이티브 플레이어',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getDescription(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDescription() {
    if (url.contains('.m3u8')) {
      return 'iOS: AVPlayer + preferredPeakBitRate\n'
          'Android: ExoPlayer + DefaultTrackSelector\n'
          'Flutter: Texture 위젯 + 커스텀 오버레이';
    }
    return 'iOS: AVPlayer + AVPlayerItemVideoOutput\n'
        'Android: ExoPlayer + SurfaceTexture\n'
        'Flutter: Texture 위젯 + 커스텀 오버레이';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
