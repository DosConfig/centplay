import 'package:flutter/material.dart';

import 'video_player_screen.dart';

/// 영상 피드 화면 — 썸네일 리스트에서 탭하면 전체화면 플레이어로 전환.
class VideoFeedScreen extends StatelessWidget {
  const VideoFeedScreen({super.key});

  static const _videos = [
    _VideoItem(
      title: 'HLS 어댑티브 스트리밍',
      subtitle: '6개 화질 · ABR 자동 전환 · 화질 수동 선택',
      url:
          'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
      badge: 'HLS',
      icon: Icons.hd_rounded,
    ),
    _VideoItem(
      title: 'Apple 기본 스트림',
      subtitle: 'HLS · 안정적인 공식 테스트 스트림',
      url:
          'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8',
      badge: 'HLS',
      icon: Icons.live_tv_rounded,
    ),
    _VideoItem(
      title: 'mp4 단일 파일 (비교군)',
      subtitle: 'ABR 없음 · 네트워크 떨어지면 버퍼링',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      badge: 'MP4',
      icon: Icons.movie_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영상'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _videos.length,
        itemBuilder: (context, i) {
          final video = _videos[i];
          return _VideoCard(
            video: video,
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    url: video.url,
                    title: video.title,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video, required this.onTap});

  final _VideoItem video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일 영역
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      // 배경
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primaryContainer,
                              colorScheme.secondaryContainer,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            video.icon,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      // 하단 그라데이션
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 재생 버튼
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      // 배지 (HLS/MP4) — GameCard의 category chip 패턴
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            video.badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 제목
            Text(
              video.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // 설명
            Text(
              video.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoItem {
  const _VideoItem({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.badge,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String url;
  final String badge;
  final IconData icon;
}
