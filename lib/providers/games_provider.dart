import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final gamesProvider = StreamProvider<List<Game>>((ref) {
  return ref.watch(firestoreServiceProvider).getGames();
});

final recommendedGamesProvider = Provider<AsyncValue<List<Game>>>((ref) {
  return ref.watch(gamesProvider).whenData(
        (games) => games.where((g) => g.isRecommended).toList(),
      );
});

final gameByIdProvider = Provider.family<Game?, String>((ref, id) {
  return ref
      .watch(gamesProvider)
      .whenData(
        (games) => games.where((g) => g.id == id).firstOrNull,
      )
      .value;
});
