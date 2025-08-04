import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/chat_service.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  String extractName(String email) {
    final username = email.split('@').first;
    final namePart = username.replaceAll(RegExp(r'\d'), '');
    return namePart.isNotEmpty
        ? namePart[0].toUpperCase() + namePart.substring(1)
        : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final chatService = context.read<ChatService>();
    final currentUid = auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('People'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            await auth.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            }
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs
              .where((doc) => doc['uid'] != currentUid)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final email = data['email'] ?? '';
              final name = extractName(email);
              final otherUserId = data['uid'];

              return FutureBuilder<QueryDocumentSnapshot?>(
                future: chatService.getLastMessage(currentUid!, otherUserId),
                builder: (context, snap) {
                  String lastMsg = '';
                  String lastTime = '';

                  if (snap.hasData && snap.data != null) {
                    final msg = snap.data!.data() as Map<String, dynamic>;
                    lastMsg = msg['text'] ?? '';
                    final ts = msg['timestamp'] as Timestamp?;
                    if (ts != null) {
                      lastTime = DateFormat.Hm().format(ts.toDate());
                    }
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text(
                      lastMsg.isNotEmpty ? lastMsg : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      lastTime,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: data['uid'],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
