import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/games_provider.dart';
import '../models/game.dart';
import '../widgets/game_card.dart';
import '../widgets/section_header.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesProvider);
    final recommendedAsync = ref.watch(recommendedGamesProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('CentPlay',
            style: TextStyle(
              fontFamily: 'SBAggroOTF',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Theme.of(context).colorScheme.primary,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context, gamesAsync.value ?? []),
          ),
          IconButton(
              icon: const Badge(
                smallSize: 8,
                child: Icon(Icons.notifications_outlined),
              ),
              onPressed: () => context.push('/notifications')),
        ],
      ),
      body: gamesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: '게임 목록을 불러올 수 없습니다',
            onRetry: () => ref.invalidate(gamesProvider)),
        data: (allGames) {
          final recommended = recommendedAsync.value ?? [];

          // If searching, show filtered results
          if (_searchQuery.isNotEmpty) {
            final filtered = allGames
                .where((g) =>
                    g.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    g.category
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                .toList();
            return _buildSearchResults(filtered);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(gamesProvider),
            child: ListView(
              children: [
                const SectionHeader(title: '추천 게임', icon: Icons.local_fire_department_rounded),
                SizedBox(
                  height: 230,
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
                const SectionHeader(title: '랭킹', icon: Icons.emoji_events_rounded),
                ...allGames.map((game) => _buildRankingTile(context, game)),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankingTile(BuildContext context, Game game) {
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: game.localThumbnail != null
              ? Image.asset(game.localThumbnail!, fit: BoxFit.cover)
              : Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Center(
                    child: Text('${game.rank}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
        ),
      ),
      title:
          Text(game.title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    );
  }

  Widget _buildSearchResults(List<Game> games) {
    if (games.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('"$_searchQuery" 검색 결과가 없습니다'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      itemBuilder: (context, index) => _buildRankingTile(context, games[index]),
    );
  }

  void _showSearch(BuildContext context, List<Game> allGames) {
    showSearch(
      context: context,
      delegate: _GameSearchDelegate(allGames),
    );
  }
}

class _GameSearchDelegate extends SearchDelegate<String> {
  final List<Game> games;

  _GameSearchDelegate(this.games) : super(searchFieldLabel: '게임 검색...');

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final filtered = games
        .where((g) =>
            g.title.toLowerCase().contains(query.toLowerCase()) ||
            g.category.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final game = filtered[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: game.localThumbnail != null
                ? Image.asset(game.localThumbnail!,
                    width: 48, height: 48, fit: BoxFit.cover)
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[200],
                    child: const Icon(Icons.gamepad)),
          ),
          title: Text(game.title),
          subtitle: Text(game.category),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              Text(' ${game.rating.toStringAsFixed(1)}'),
            ],
          ),
          onTap: () {
            close(context, game.id);
            GoRouter.of(context).push('/game/${game.id}');
          },
        );
      },
    );
  }
}
