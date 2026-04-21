import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    final navigator = GoRouter.of(context);
    final authService = ref.read(authServiceProvider);
    final credential = await authService.signInWithGoogle();
    if (credential?.user != null) {
      final user = credential!.user!;
      await FirestoreService().saveUserProfile(
        user.uid,
        user.displayName ?? '',
        user.email ?? '',
        user.photoURL,
      );
      navigator.go('/home');
    }
  }

  Future<void> _signInAnonymously(BuildContext context, WidgetRef ref) async {
    final navigator = GoRouter.of(context);
    final authService = ref.read(authServiceProvider);
    final credential = await authService.signInAnonymously();
    if (credential.user != null) {
      final user = credential.user!;
      await FirestoreService().saveUserProfile(
        user.uid,
        user.displayName ?? 'Guest',
        user.email ?? '',
        user.photoURL,
      );
      navigator.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.games,
                  size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text('CentPlay',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('미니게임을 즐겨보세요',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _signInWithGoogle(context, ref),
                  icon: const Icon(Icons.login),
                  label: const Text('Google로 시작하기'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _signInAnonymously(context, ref),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('게스트로 둘러보기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
