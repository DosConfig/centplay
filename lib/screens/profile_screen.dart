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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 24),
              // Avatar
              Center(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.secondary],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: cs.surface,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            (user.displayName ?? 'G')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'SBAggroOTF',
                              color: cs.primary,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 14)),
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
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Guest',
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              _SectionLabel(label: '내 활동'),
              _MenuCard(
                children: [
                  _MenuTile(
                    icon: Icons.favorite_rounded,
                    title: '찜한 게임',
                    trailing: '$favoritesCount개',
                    onTap: () => context.push('/favorites'),
                  ),
                  _MenuTile(
                    icon: Icons.people_rounded,
                    title: '친구',
                    trailing: '$friendsCount명',
                    onTap: () => context.push('/friends'),
                  ),
                  _MenuTile(
                    icon: Icons.shopping_bag_rounded,
                    title: '상점',
                    onTap: () => context.push('/shop'),
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _SectionLabel(label: '설정'),
              _MenuCard(
                children: [
                  // Theme row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        _IconBox(icon: Icons.palette_rounded, cs: cs, isDark: isDark),
                        const SizedBox(width: 14),
                        const Text('테마', style: TextStyle(fontSize: 15)),
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
                  _MenuTile(
                    icon: Icons.notifications_rounded,
                    title: '알림 설정',
                    onTap: () => context.push('/notifications'),
                  ),
                  _MenuTile(
                    icon: Icons.language_rounded,
                    title: '언어',
                    trailing: '한국어',
                    onTap: () {},
                  ),
                  _MenuTile(
                    icon: Icons.gamepad_rounded,
                    title: '컨트롤러 설정',
                    trailing: 'Bluetooth',
                    onTap: () => context.push('/controller-settings'),
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _SectionLabel(label: '정보'),
              _MenuCard(
                children: [
                  _MenuTile(
                    icon: Icons.info_outline_rounded,
                    title: '앱 버전',
                    trailing: '1.0.0',
                    onTap: () {},
                  ),
                  _MenuTile(
                    icon: Icons.description_outlined,
                    title: '이용약관',
                    onTap: () {},
                  ),
                  _MenuTile(
                    icon: Icons.shield_outlined,
                    title: '개인정보 처리방침',
                    onTap: () {},
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('로그아웃'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 40),
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

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;
  final bool isDark;
  const _IconBox({required this.icon, required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isDark
            ? cs.primary.withValues(alpha: 0.15)
            : cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon,
          size: 18, color: isDark ? cs.primary.withValues(alpha: 0.8) : cs.primary),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  final bool isLast;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                _IconBox(icon: icon, cs: cs, isDark: isDark),
                const SizedBox(width: 14),
                Expanded(
                    child:
                        Text(title, style: const TextStyle(fontSize: 15))),
                if (trailing != null)
                  Text(trailing!,
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 14)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 0,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
      ],
    );
  }
}
