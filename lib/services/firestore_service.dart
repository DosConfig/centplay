import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';
import '../models/video.dart';
import '../models/friend.dart';
import '../models/chat_message.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Games
  Stream<List<Game>> getGames() {
    return _db.collection('games').orderBy('rank').snapshots().map(
          (snap) => snap.docs.map((doc) => Game.fromFirestore(doc)).toList(),
        );
  }

  // Videos
  Stream<List<Video>> getVideos() {
    return _db.collection('videos').snapshots().map(
          (snap) => snap.docs.map((doc) => Video.fromFirestore(doc)).toList(),
        );
  }

  // Favorites
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

  // User profile
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

  // Friends
  Stream<List<Friend>> getFriends(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Friend.fromFirestore(doc)).toList());
  }

  Future<void> addFriend(String uid, String friendUid) async {
    final friendDoc = await _db.collection('users').doc(friendUid).get();
    if (!friendDoc.exists) return;

    final friendData = friendDoc.data()!;
    final myDoc = await _db.collection('users').doc(uid).get();
    final myData = myDoc.data() ?? {};

    // Add friend to my list
    await _db.collection('users').doc(uid).collection('friends').doc(friendUid).set({
      'displayName': friendData['displayName'] ?? '',
      'email': friendData['email'] ?? '',
      'photoUrl': friendData['photoUrl'] ?? '',
      'addedAt': FieldValue.serverTimestamp(),
    });

    // Add me to friend's list (mutual)
    await _db.collection('users').doc(friendUid).collection('friends').doc(uid).set({
      'displayName': myData['displayName'] ?? '',
      'email': myData['email'] ?? '',
      'photoUrl': myData['photoUrl'] ?? '',
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFriend(String uid, String friendUid) async {
    await _db.collection('users').doc(uid).collection('friends').doc(friendUid).delete();
    await _db.collection('users').doc(friendUid).collection('friends').doc(uid).delete();
  }

  // Search users by email
  Future<List<Map<String, dynamic>>> searchUsers(String email) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(5)
        .get();
    return snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
  }

  // Chat
  String _chatRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<List<ChatMessage>> getMessages(String myUid, String friendUid) {
    final roomId = _chatRoomId(myUid, friendUid);
    return _db
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage(String myUid, String myName, String friendUid, String text) async {
    final roomId = _chatRoomId(myUid, friendUid);
    final roomRef = _db.collection('chatRooms').doc(roomId);

    await roomRef.collection('messages').add({
      'senderId': myUid,
      'senderName': myName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update room metadata for unread badge
    await roomRef.set({
      'lastMessage': text,
      'lastSenderId': myUid,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'participants': [myUid, friendUid],
    }, SetOptions(merge: true));
  }

  // Unread count across all chat rooms
  Stream<int> getUnreadCount(String uid) {
    return _db
        .collection('chatRooms')
        .where('participants', arrayContains: uid)
        .where('lastSenderId', isNotEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
