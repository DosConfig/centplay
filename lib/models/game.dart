import 'package:cloud_firestore/cloud_firestore.dart';

class Game {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String webglUrl;
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
    required this.rank,
    required this.rating,
    required this.isRecommended,
    required this.category,
  });

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      webglUrl: data['webglUrl'] ?? '',
      rank: (data['rank'] ?? 0) as int,
      rating: (data['rating'] ?? 0.0).toDouble(),
      isRecommended: data['isRecommended'] ?? false,
      category: data['category'] ?? '',
    );
  }
}
