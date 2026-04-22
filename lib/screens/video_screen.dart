import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/videos_provider.dart';
import '../models/video.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_widget.dart';

class VideoScreen extends ConsumerWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(videosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('영상 컨텐츠')),
      body: videosAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: '영상을 불러올 수 없습니다',
            onRetry: () => ref.invalidate(videosProvider)),
        data: (videos) {
          if (videos.isEmpty) {
            return const EmptyWidget(
                message: '영상이 없습니다', icon: Icons.videocam_off);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _VideoCard(video: videos[index]),
          );
        },
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final Video video;
  const _VideoCard({required this.video});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;

  void _initPlayer() {
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
          ..initialize().then((_) {
            if (!mounted) return;
            _controller!.play();
            setState(() => _isPlaying = true);
          });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _isPlaying &&
                    _controller != null &&
                    _controller!.value.isInitialized
                ? VideoPlayer(_controller!)
                : GestureDetector(
                    onTap: _initPlayer,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        widget.video.localThumbnail != null
                            ? Image.asset(widget.video.localThumbnail!, width: double.infinity, fit: BoxFit.cover)
                            : CachedNetworkImage(
                                imageUrl: widget.video.thumbnailUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: Colors.grey[300]),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.videocam,
                                      size: 48, color: Colors.grey),
                                ),
                              ),
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.play_arrow,
                              size: 36, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.video.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '조회수 ${_formatViewCount(widget.video.viewCount)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatViewCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}만';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}천';
    return '$count';
  }
}
