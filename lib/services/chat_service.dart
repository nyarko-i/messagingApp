import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getMessageStream() {
    return _db
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(String text, String senderId) async {
    if (text.trim().isEmpty) return;
    await _db.collection('messages').add({
      'text': text.trim(),
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }
}
