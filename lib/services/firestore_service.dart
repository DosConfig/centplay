import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';
import '../models/video.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Game>> getGames() {
    return _db.collection('games').orderBy('rank').snapshots().map(
          (snap) => snap.docs.map((doc) => Game.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Video>> getVideos() {
    return _db.collection('videos').snapshots().map(
          (snap) => snap.docs.map((doc) => Video.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<String>> getFavorites(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }

  Future<void> toggleFavorite(String uid, String gameId) async {
    final docRef =
        _db.collection('users').doc(uid).collection('favorites').doc(gameId);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'addedAt': FieldValue.serverTimestamp(),
        'gameRef': 'games/$gameId',
      });
    }
  }

  Future<void> saveUserProfile(
    String uid,
    String displayName,
    String email,
    String? photoUrl,
  ) async {
    await _db.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
