import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centplay/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: fakeFirestore);
  });

  group('saveUserProfile', () {
    test('새 프로필 저장', () async {
      await service.saveUserProfile('uid1', 'TestUser', 'test@test.com', null);

      final doc = await fakeFirestore.collection('users').doc('uid1').get();
      expect(doc.exists, true);
      expect(doc.data()!['displayName'], 'TestUser');
      expect(doc.data()!['email'], 'test@test.com');
      expect(doc.data()!['photoUrl'], '');
    });

    test('기존 프로필 merge 업데이트', () async {
      await service.saveUserProfile('uid1', 'Old', 'old@test.com', null);
      await service.saveUserProfile(
          'uid1', 'New', 'new@test.com', 'http://photo.jpg');

      final doc = await fakeFirestore.collection('users').doc('uid1').get();
      expect(doc.data()!['displayName'], 'New');
      expect(doc.data()!['photoUrl'], 'http://photo.jpg');
    });
  });

  group('favorites', () {
    test('즐겨찾기 추가 후 목록에 포함', () async {
      await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('favorites')
          .doc('game1')
          .set({'addedAt': DateTime.now().toIso8601String()});

      final favorites = await service.getFavorites('uid1').first;
      expect(favorites, contains('game1'));
    });

    test('toggleFavorite — 없으면 추가, 있으면 제거', () async {
      // 추가
      await service.toggleFavorite('uid1', 'game1');
      var favs = await service.getFavorites('uid1').first;
      expect(favs, contains('game1'));

      // 제거
      await service.toggleFavorite('uid1', 'game1');
      favs = await service.getFavorites('uid1').first;
      expect(favs, isNot(contains('game1')));
    });
  });

  group('games', () {
    test('getGames → Firestore 문서를 Game 모델로 변환', () async {
      await fakeFirestore.collection('games').doc('g1').set({
        'title': 'Test Game',
        'description': 'A test',
        'thumbnailUrl': 'http://thumb.jpg',
        'webglUrl': 'http://game.html',
        'trailerUrl': '',
        'rank': 1,
        'rating': 4.5,
        'isRecommended': true,
        'category': 'Action',
      });

      final games = await service.getGames().first;
      expect(games.length, 1);
      expect(games.first.title, 'Test Game');
      expect(games.first.rating, 4.5);
      expect(games.first.isRecommended, true);
    });
  });

  group('friends', () {
    test('addFriend → 양방향 추가', () async {
      await fakeFirestore.collection('users').doc('uid2').set({
        'displayName': 'Friend',
        'email': 'friend@test.com',
        'photoUrl': '',
      });
      await fakeFirestore.collection('users').doc('uid1').set({
        'displayName': 'Me',
        'email': 'me@test.com',
        'photoUrl': '',
      });

      await service.addFriend('uid1', 'uid2');

      final myFriends = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('friends')
          .get();
      final theirFriends = await fakeFirestore
          .collection('users')
          .doc('uid2')
          .collection('friends')
          .get();

      expect(myFriends.docs.length, 1);
      expect(theirFriends.docs.length, 1);
    });

    test('removeFriend → 양방향 제거', () async {
      await fakeFirestore.collection('users').doc('uid2').set({
        'displayName': 'Friend',
        'email': 'f@t.com',
        'photoUrl': '',
      });
      await fakeFirestore.collection('users').doc('uid1').set({
        'displayName': 'Me',
        'email': 'm@t.com',
        'photoUrl': '',
      });
      await service.addFriend('uid1', 'uid2');
      await service.removeFriend('uid1', 'uid2');

      final myFriends = await fakeFirestore
          .collection('users')
          .doc('uid1')
          .collection('friends')
          .get();
      expect(myFriends.docs, isEmpty);
    });
  });

  group('seedMDC', () {
    test('idempotent — 두 번 호출해도 덮어쓰지 않음', () async {
      await service.seedMDC();
      final firstCall = await fakeFirestore
          .collection('games')
          .doc('mdc')
          .get();
      expect(firstCall.exists, true);

      final firstTitle = firstCall.data()!['title'];
      await service.seedMDC();

      final secondCall = await fakeFirestore
          .collection('games')
          .doc('mdc')
          .get();
      expect(secondCall.data()!['title'], firstTitle);
    });
  });
}
