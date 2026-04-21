import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video.dart';
import 'games_provider.dart';

final videosProvider = StreamProvider<List<Video>>((ref) {
  return ref.watch(firestoreServiceProvider).getVideos();
});
