import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centplay/providers/games_provider.dart';
import 'package:centplay/providers/theme_provider.dart';
import 'package:centplay/services/firestore_service.dart';

void main() {
  group('themeModeProvider', () {
    test('기본값 dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('light로 전환', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });

  group('gamesProvider', () {
    Future<FakeFirebaseFirestore> setupFirestoreWithGame() async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('games').doc('g1').set({
        'title': 'Test Game',
        'description': 'desc',
        'thumbnailUrl': '',
        'webglUrl': '',
        'trailerUrl': '',
        'rank': 1,
        'rating': 4.0,
        'isRecommended': false,
        'category': 'Puzzle',
      });
      return fakeFirestore;
    }

    test('Firestore 문서 → Game 리스트', () async {
      final fakeFirestore = await setupFirestoreWithGame();

      final container = ProviderContainer(
        overrides: [
          firestoreServiceProvider.overrideWithValue(
            FirestoreService(firestore: fakeFirestore),
          ),
        ],
      );
      addTearDown(container.dispose);

      final games = await container.read(gamesProvider.future);
      expect(games.length, 1);
      expect(games.first.title, 'Test Game');
      expect(games.first.category, 'Puzzle');
    });

    test('gameByIdProvider → ID로 검색', () async {
      final fakeFirestore = await setupFirestoreWithGame();

      final container = ProviderContainer(
        overrides: [
          firestoreServiceProvider.overrideWithValue(
            FirestoreService(firestore: fakeFirestore),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gamesProvider.future);
      final game = container.read(gameByIdProvider('g1'));

      expect(game, isNotNull);
      expect(game!.title, 'Test Game');
    });

    test('recommendedGamesProvider → isRecommended 필터', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final base = {
        'description': '',
        'thumbnailUrl': '',
        'webglUrl': '',
        'trailerUrl': '',
        'rank': 1,
        'rating': 4.0,
        'category': 'Action',
      };
      await fakeFirestore.collection('games').doc('g1').set({
        ...base,
        'title': 'Recommended',
        'isRecommended': true,
      });
      await fakeFirestore.collection('games').doc('g2').set({
        ...base,
        'title': 'Not Recommended',
        'isRecommended': false,
      });

      final container = ProviderContainer(
        overrides: [
          firestoreServiceProvider.overrideWithValue(
            FirestoreService(firestore: fakeFirestore),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gamesProvider.future);
      final recommended = container.read(recommendedGamesProvider).value!;

      expect(recommended.length, 1);
      expect(recommended.first.title, 'Recommended');
    });
  });
}
