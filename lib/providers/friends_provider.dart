import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend.dart';
import '../models/chat_message.dart';
import 'auth_provider.dart';
import 'games_provider.dart';

final friendsProvider = StreamProvider<List<Friend>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getFriends(user.uid);
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, friendUid) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getMessages(user.uid, friendUid);
});

final unreadCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(0);
  return ref.watch(firestoreServiceProvider).getUnreadCount(user.uid);
});
