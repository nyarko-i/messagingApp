import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String? email;

  AppUser({required this.uid, this.email});

  factory AppUser.fromFirebase(User u) => AppUser(uid: u.uid, email: u.email);
}
