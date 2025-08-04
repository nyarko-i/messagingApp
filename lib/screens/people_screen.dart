import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final currentUid = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Chat'),
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
        builder: (c, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs.where((d) => d['uid'] != currentUid);
          return ListView(
            children: docs.map((d) {
              return ListTile(
                title: Text(d['email'] ?? ''),
                onTap: () {
                  Navigator.pushNamed(context, '/chat', arguments: d['uid']);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
