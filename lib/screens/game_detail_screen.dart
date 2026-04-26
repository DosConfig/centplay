import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' as sp;
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/games_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/game_card.dart';
import '../widgets/native_video_player.dart';
import '../widgets/section_header.dart';
import '../widgets/loading_widget.dart';

class GameDetailScreen extends ConsumerWidget {
  final String id;

  const GameDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameByIdProvider(id));
    final isFavorite = ref.watch(isFavoriteProvider(id));
    final allGames = ref.watch(gamesProvider).value ?? [];
    final similar = allGames.where((g) => g.id != id).take(4).toList();

    if (game == null) return const Scaffold(body: LoadingWidget());

    return Scaffold(
      appBar: AppBar(title: Text(game.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero thumbnail
            game.localThumbnail != null
                ? Image.asset(game.localThumbnail!,
                    width: double.infinity, height: 220, fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: game.thumbnailUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(height: 220, color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(
                      height: 220,
                      color: Colors.grey[200],
                      child:
                          const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(game.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Icon(Icons.star_rounded, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(game.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(game.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.grey[500])),
                  const SizedBox(height: 24),
                  // Gradient play button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE200FF), Color(0xFF4765FF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFE200FF).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: () => context.push('/game/$id/play'),
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text('게임 시작',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: isFavorite
                            ? Icons.favorite
                            : Icons.favorite_outline,
                        label: '찜',
                        color: isFavorite ? Colors.red : null,
                        onTap: () => ref.read(toggleFavoriteProvider)(id),
                      ),
                      _ActionButton(
                        icon: Icons.share,
                        label: '공유',
                        onTap: () => sp.Share.share(
                          '${game.title}을 CentPlay에서 플레이해보세요!',
                        ),
                      ),
                      _ActionButton(
                        icon: Icons.shopping_cart_outlined,
                        label: '상점',
                        onTap: () => context.push('/shop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Gameplay trailer (네이티브 플랫폼 채널 플레이어)
            if (game.trailerUrl.isNotEmpty) ...[
              const SectionHeader(
                  title: '게임플레이 영상', icon: Icons.videocam_rounded),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: NativeVideoPlayer(
                    url: game.trailerUrl,
                    autoPlay: false,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Similar games
            if (similar.isNotEmpty) ...[
              const SectionHeader(title: '비슷한 게임', icon: Icons.grid_view_rounded),
              SizedBox(
                height: 230,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: similar.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return GameCard(
                      game: similar[index],
                      onTap: () => context.push('/game/${similar[index].id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
