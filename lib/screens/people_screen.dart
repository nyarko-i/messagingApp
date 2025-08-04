import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';

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
    final currentUid = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('People'),
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
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs.where(
            (doc) => doc['uid'] != currentUid,
          );

          if (users.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final user = users.elementAt(index);
              final data = user.data() as Map<String, dynamic>;
              final email = data['email'] ?? '';
              final name = extractName(email);

              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blueGrey.shade100,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () {
                  Navigator.pushNamed(context, '/chat', arguments: data['uid']);
                },
              );
            },
          );
        },
      ),
    );
  }
}
