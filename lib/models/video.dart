import 'package:cloud_firestore/cloud_firestore.dart';

class Video {
  final String id;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final int viewCount;

  const Video({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.viewCount,
  });

  factory Video.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Video(
      id: doc.id,
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      viewCount: (data['viewCount'] ?? 0) as int,
    );
  }
}
