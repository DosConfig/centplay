import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/games_provider.dart';

// Simple in-memory notification state
final _notificationsProvider =
    StateNotifierProvider<_NotifNotifier, List<_NotifItem>>(
        (ref) => _NotifNotifier(ref));

class _NotifNotifier extends StateNotifier<List<_NotifItem>> {
  _NotifNotifier(Ref ref) : super(_buildInitial(ref));

  static List<_NotifItem> _buildInitial(Ref ref) {
    final games = ref.read(gamesProvider).value ?? [];
    return [
      _NotifItem(
        id: '1',
        icon: Icons.new_releases_rounded,
        title: '새로운 게임 추가!',
        body: '2048이 CentPlay에 등록되었습니다. 지금 바로 플레이해보세요!',
        time: '방금 전',
        route: games.isNotEmpty ? '/game/${games.last.id}' : null,
      ),
      _NotifItem(
        id: '2',
        icon: Icons.emoji_events_rounded,
        title: '랭킹 업데이트',
        body: '이번 주 인기 게임 랭킹이 갱신되었습니다.',
        time: '1시간 전',
        route: '/home',
      ),
      _NotifItem(
        id: '3',
        icon: Icons.card_giftcard_rounded,
        title: '보너스 코인 지급',
        body: '출석 보상으로 50 코인이 지급되었습니다.',
        time: '3시간 전',
        route: '/shop',
      ),
      _NotifItem(
        id: '4',
        icon: Icons.update_rounded,
        title: 'Bubble Tower 3D 업데이트',
        body: '새로운 스테이지 50개가 추가되었습니다!',
        time: '어제',
        route: games.isNotEmpty ? '/game/${games.first.id}' : null,
      ),
      _NotifItem(
        id: '5',
        icon: Icons.people_rounded,
        title: '친구 추천',
        body: '이메일 주소로 친구를 추가하고 함께 게임을 즐겨보세요.',
        time: '2일 전',
        route: '/friends',
      ),
    ];
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void delete(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(_notificationsProvider);
    final notifier = ref.read(_notificationsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: Text('모두 읽음',
                  style: TextStyle(color: colorScheme.primary, fontSize: 13)),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('알림이 없습니다',
                      style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => notifier.delete(n.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.withValues(alpha: 0.1),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  child: Container(
                    color: n.isRead
                        ? Colors.transparent
                        : colorScheme.primary.withValues(alpha: 0.04),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(n.icon, color: colorScheme.primary, size: 22),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(n.title,
                                style: TextStyle(
                                  fontWeight: n.isRead
                                      ? FontWeight.w400
                                      : FontWeight.w700,
                                  fontSize: 14,
                                )),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(n.body,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[500]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(n.time,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400])),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        notifier.markAsRead(n.id);
                        if (n.route != null) {
                          context.go(n.route!);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _NotifItem {
  final String id;
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final String? route;
  final bool isRead;

  const _NotifItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.route,
    this.isRead = false,
  });

  _NotifItem copyWith({bool? isRead}) => _NotifItem(
        id: id,
        icon: icon,
        title: title,
        body: body,
        time: time,
        route: route,
        isRead: isRead ?? this.isRead,
      );
}
