import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/games_provider.dart';
import '../widgets/game_card.dart';
import '../widgets/section_header.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider);
    final recommendedAsync = ref.watch(recommendedGamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CentPlay',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {}),
        ],
      ),
      body: gamesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: '게임 목록을 불러올 수 없습니다',
            onRetry: () => ref.invalidate(gamesProvider)),
        data: (allGames) {
          final recommended = recommendedAsync.value ?? [];
          return ListView(
            children: [
              const SectionHeader(title: '추천 게임'),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recommended.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final game = recommended[index];
                    return GameCard(
                      game: game,
                      onTap: () => context.push('/game/${game.id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const SectionHeader(title: '랭킹'),
              ...allGames.map((game) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text('${game.rank}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(game.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(game.category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(game.rating.toStringAsFixed(1)),
                      ],
                    ),
                    onTap: () => context.push('/game/${game.id}'),
                  )),
            ],
          );
        },
      ),
    );
  }
}
