import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final favoritesCount = ref.watch(favoritesProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('프로필을 불러올 수 없습니다')),
        data: (user) {
          if (user == null) {
            return Center(
              child: FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('로그인'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 24),
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.displayName ?? '사용자',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(user.email ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey)),
              ),
              const SizedBox(height: 32),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.favorite),
                      title: const Text('찜한 게임'),
                      trailing: Text('$favoritesCount개',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
              ),
            ],
          );
        },
      ),
    );
  }
}
