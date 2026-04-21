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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Logo area
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.games_rounded,
                    size: 52, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text(
                'CentPlay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '미니게임을 즐겨보세요',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                ),
              ),
              const Spacer(flex: 2),
              // Google Sign In
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _signInWithGoogle(context, ref),
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text('Google로 시작하기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0A0A0A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Guest
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _signInAnonymously(context, ref),
                  icon: const Icon(Icons.person_outline, size: 20),
                  label: const Text('게스트로 둘러보기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.grey[700]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Powered by Flutter + Firebase',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
