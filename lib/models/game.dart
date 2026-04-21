import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String webglUrl;
  final String trailerUrl;
  final int rank;
  final double rating;
  final bool isRecommended;
  final String category;

  const Game({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.webglUrl,
    required this.trailerUrl,
    required this.rank,
    required this.rating,
    required this.isRecommended,
    required this.category,
  });

  static const _localThumbnails = {
    'pizza-ready': 'assets/images/games/bubble_tower_3d.png',
    'burger-please': 'assets/images/games/cut_the_rope.jpg',
    'snake-clash': 'assets/images/games/slope.jpg',
    'xp-hero': 'assets/images/games/moto_x3m.jpg',
    'centplay-demo': 'assets/images/games/2048.jpg',
  };

  String? get localThumbnail => _localThumbnails[id];

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      webglUrl: data['webglUrl'] ?? '',
      trailerUrl: data['trailerUrl'] ?? '',
      rank: (data['rank'] ?? 0) as int,
      rating: (data['rating'] ?? 0.0).toDouble(),
      isRecommended: data['isRecommended'] ?? false,
      category: data['category'] ?? '',
    );
  }
}
