import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/games_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_widget.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddFriendDialog(context, ref),
          ),
        ],
      ),
      body: friendsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (friends) {
          if (friends.isEmpty) {
            return const EmptyWidget(
              message: '아직 친구가 없어요\n오른쪽 상단 + 버튼으로 추가해보세요',
              icon: Icons.people_outline,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: friend.photoUrl.isNotEmpty
                      ? NetworkImage(friend.photoUrl)
                      : null,
                  child: friend.photoUrl.isEmpty
                      ? Text(friend.displayName.isNotEmpty
                          ? friend.displayName[0].toUpperCase()
                          : '?')
                      : null,
                ),
                title: Text(friend.displayName.isNotEmpty
                    ? friend.displayName
                    : 'Guest'),
                subtitle: Text(friend.email,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => context.push('/chat/${friend.uid}'),
                ),
                onTap: () => context.push('/chat/${friend.uid}'),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('친구 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '이메일 주소를 입력하세요',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;

              final firestore = ref.read(firestoreServiceProvider);
              final results = await firestore.searchUsers(email);
              final myUid = ref.read(authStateProvider).value?.uid;

              if (!ctx.mounted) return;

              if (results.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('해당 이메일의 사용자를 찾을 수 없습니다')),
                );
                Navigator.pop(ctx);
                return;
              }

              final friendData = results.first;
              if (friendData['uid'] == myUid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('자기 자신은 추가할 수 없습니다')),
                );
                Navigator.pop(ctx);
                return;
              }

              await firestore.addFriend(myUid!, friendData['uid']);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('${friendData['displayName']}님을 친구로 추가했습니다')),
                );
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}
