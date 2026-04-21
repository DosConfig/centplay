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

  static const _localThumbnails = {
    'video-1': 'assets/images/videos/video_1.jpg',
    'video-2': 'assets/images/videos/video_2.jpg',
  };

  String? get localThumbnail => _localThumbnails[id];

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
