import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  const ChatScreen({required this.receiverId, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) {
      return;
    }

    final auth = context.read<AuthService>();
    final chat = context.read<ChatService>();
    final me = auth.currentUser!.uid;

    await chat.sendMessage(text, me, widget.receiverId);
    _msgCtrl.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.minScrollExtent);
      }
    });
  }

  Future<void> _signOut() async {
    await context.read<AuthService>().signOut();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final chat = context.watch<ChatService>();
    final me = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chat.getConversation(me, widget.receiverId),
              builder: (c, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                return ListView.builder(
                  reverse: true,
                  controller: _scrollCtrl,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m = docs[i].data() as Map<String, dynamic>;
                    final isMe = m['senderId'] == me;
                    return _MsgBubble(text: m['text'] ?? '', isMe: isMe);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: ValueKey(_msgCtrl.text),
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                TextButton(onPressed: _sendMessage, child: const Text('Send')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple bubble widget for each message.
class _MsgBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  const _MsgBubble({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bgColor = isMe ? Colors.blue[100] : Colors.grey[300];
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, borderRadius: radius),
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
