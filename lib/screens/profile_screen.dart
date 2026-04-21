import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final favoritesCount = ref.watch(favoritesProvider).value?.length ?? 0;
    final friendsCount = ref.watch(friendsProvider).value?.length ?? 0;
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
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
              const SizedBox(height: 16),
              // Avatar with gradient ring
              Center(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.surface,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            (user.displayName ?? 'G')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SBAggroOTF',
                              color: colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
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
              if (user.email != null && user.email!.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(user.email!,
                        style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ),
                ),
              if (user.isAnonymous)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Guest',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              // === My Activity ===
              _SectionLabel(label: '내 활동'),
              Card(
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.favorite_rounded,
                      iconColor: Colors.red,
                      title: '찜한 게임',
                      trailing: '$favoritesCount개',
                      onTap: () => context.push('/favorites'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _ProfileTile(
                      icon: Icons.people_rounded,
                      iconColor: colorScheme.secondary,
                      title: '친구',
                      trailing: '$friendsCount명',
                      onTap: () => context.push('/friends'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _ProfileTile(
                      icon: Icons.shopping_bag_rounded,
                      iconColor: Colors.green,
                      title: '상점',
                      onTap: () => context.push('/shop'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // === Settings ===
              _SectionLabel(label: '설정'),
              Card(
                child: Column(
                  children: [
                    // Theme
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.palette_rounded,
                                size: 20, color: Colors.deepPurple),
                          ),
                          const SizedBox(width: 12),
                          const Text('테마'),
                          const Spacer(),
                          SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            segments: const [
                              ButtonSegment(
                                  value: ThemeMode.light,
                                  icon: Icon(Icons.light_mode, size: 15)),
                              ButtonSegment(
                                  value: ThemeMode.system,
                                  icon: Icon(Icons.auto_mode, size: 15)),
                              ButtonSegment(
                                  value: ThemeMode.dark,
                                  icon: Icon(Icons.dark_mode, size: 15)),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: (s) {
                              ref.read(themeModeProvider.notifier).state =
                                  s.first;
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _ProfileTile(
                      icon: Icons.notifications_rounded,
                      iconColor: Colors.orange,
                      title: '알림 설정',
                      onTap: () => context.push('/notifications'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _ProfileTile(
                      icon: Icons.language_rounded,
                      iconColor: Colors.teal,
                      title: '언어',
                      trailing: '한국어',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _ProfileTile(
                      icon: Icons.gamepad_rounded,
                      iconColor: colorScheme.primary,
                      title: '컨트롤러 설정',
                      trailing: 'Bluetooth',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // === About ===
              _SectionLabel(label: '정보'),
              Card(
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.grey,
                      title: '앱 버전',
                      trailing: '1.0.0',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _ProfileTile(
                      icon: Icons.description_outlined,
                      iconColor: Colors.grey,
                      title: '이용약관',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _ProfileTile(
                      icon: Icons.shield_outlined,
                      iconColor: Colors.grey,
                      title: '개인정보 처리방침',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Logout
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('로그아웃'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          )),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!,
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
        ],
      ),
      onTap: onTap,
    );
  }
}
