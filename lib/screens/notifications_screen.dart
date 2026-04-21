import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/games_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesProvider).value ?? [];
    final colorScheme = Theme.of(context).colorScheme;

    // Demo notifications based on game data
    final notifications = [
      _NotifItem(
        icon: Icons.new_releases_rounded,
        color: colorScheme.primary,
        title: '새로운 게임 추가!',
        body: '2048이 CentPlay에 등록되었습니다. 지금 바로 플레이해보세요!',
        time: '방금 전',
        route: games.isNotEmpty ? '/game/${games.last.id}' : null,
      ),
      _NotifItem(
        icon: Icons.emoji_events_rounded,
        color: Colors.amber,
        title: '랭킹 업데이트',
        body: '이번 주 인기 게임 랭킹이 갱신되었습니다.',
        time: '1시간 전',
        route: '/home',
      ),
      _NotifItem(
        icon: Icons.card_giftcard_rounded,
        color: Colors.green,
        title: '보너스 코인 지급',
        body: '출석 보상으로 50 코인이 지급되었습니다.',
        time: '3시간 전',
        route: '/shop',
      ),
      _NotifItem(
        icon: Icons.update_rounded,
        color: colorScheme.secondary,
        title: 'Bubble Tower 3D 업데이트',
        body: '새로운 스테이지 50개가 추가되었습니다!',
        time: '어제',
        route: games.isNotEmpty ? '/game/${games.first.id}' : null,
      ),
      _NotifItem(
        icon: Icons.people_rounded,
        color: Colors.orange,
        title: '친구 추천',
        body: '이메일 주소로 친구를 추가하고 함께 게임을 즐겨보세요.',
        time: '2일 전',
        route: '/friends',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: n.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(n.icon, color: n.color, size: 22),
            ),
            title: Text(n.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(n.body,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(n.time,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              if (n.route != null) {
                Navigator.pop(context);
                context.push(n.route!);
              }
            },
          );
        },
      ),
    );
  }
}

class _NotifItem {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  final String? route;

  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    this.route,
  });
}
