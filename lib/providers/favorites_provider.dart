import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'games_provider.dart';

final favoritesProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getFavorites(user.uid);
});

final isFavoriteProvider = Provider.family<bool, String>((ref, gameId) {
  final favorites = ref.watch(favoritesProvider).value ?? [];
  return favorites.contains(gameId);
});

final toggleFavoriteProvider = Provider((ref) {
  return (String gameId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await ref.read(firestoreServiceProvider).toggleFavorite(user.uid, gameId);
  };
});
