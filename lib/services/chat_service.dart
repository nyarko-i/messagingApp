import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generates a consistent chat ID between two users
  String getChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Stream messages between two specific users
  Stream<QuerySnapshot> getConversation(String userId, String otherId) {
    final chatId = getChatId(userId, otherId);
    return _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Send a message
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
    });

    notifyListeners();
  }
}
