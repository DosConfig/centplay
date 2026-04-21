import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/favorites_provider.dart';
import '../providers/games_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_widget.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final gamesAsync = ref.watch(gamesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 찜 목록')),
      body: favoritesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) =>
            const Center(child: Text('찜 목록을 불러올 수 없습니다')),
        data: (favoriteIds) {
          if (favoriteIds.isEmpty) {
            return const EmptyWidget(
                message: '아직 찜한 게임이 없어요',
                icon: Icons.favorite_outline);
          }

          final allGames = gamesAsync.value ?? [];
          final favoriteGames =
              allGames.where((g) => favoriteIds.contains(g.id)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteGames.length,
            itemBuilder: (context, index) {
              final game = favoriteGames[index];
              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      game.thumbnailUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[200],
                          child: const Icon(Icons.gamepad)),
                    ),
                  ),
                  title: Text(game.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(game.rating.toStringAsFixed(1)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () =>
                        ref.read(toggleFavoriteProvider)(game.id),
                  ),
                  onTap: () => context.push('/game/${game.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
