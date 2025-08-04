import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String getChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<QuerySnapshot> getConversation(String userId, String otherId) {
    final chatId = getChatId(userId, otherId);
    return _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(
    String text,
    String senderId,
    String receiverId,
  ) async {
    if (text.trim().isEmpty) return;

    final chatId = getChatId(senderId, receiverId);

    await _db.collection('messages').add({
      'text': text.trim(),
      'senderId': senderId,
      'receiverId': receiverId,
      'participants': [senderId, receiverId],
      'chatId': chatId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    notifyListeners();
  }

  Future<QueryDocumentSnapshot?> getLastMessage(
    String userId,
    String otherId,
  ) async {
    final chatId = getChatId(userId, otherId);

    final snap = await _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    return snap.docs.isEmpty ? null : snap.docs.first;
  }
}
