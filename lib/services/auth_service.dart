// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Use the singleton instance — do NOT call `GoogleSignIn()` or `GoogleSignIn.standard()`
  final GoogleSignIn _google = GoogleSignIn.instance;

  bool _isGoogleInitialized = false;

  AuthService() {
    _initGoogle(); // async, but OK if not awaited immediately
  }

  Future<void> _initGoogle() async {
    if (!_isGoogleInitialized) {
      try {
        await GoogleSignIn.instance.initialize(); // 🔑 mandatory v7 init
        _isGoogleInitialized = true;
      } catch (e, st) {
        debugPrint('GoogleSignIn.initialize failed: $e\n$st');
      }
    }
  }

  Future<void> _ensureUserInFirestore(User u) async {
    final doc = _firestore.collection('users').doc(u.uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      await doc.set({
        'uid': u.uid,
        'email': u.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureUserInFirestore(cred.user!);
    notifyListeners();
    return cred.user;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureUserInFirestore(cred.user!);
    notifyListeners();
    return cred.user;
  }

  /// Returns current user after sign-in
  Future<User?> signInWithGoogle() async {
    await _initGoogle();
    late final GoogleSignInAccount googleUser;

    try {
      googleUser = await _google.authenticate(scopeHint: ['email']);
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignIn error: code=${e.code.name}, desc=${e.cause}');
      rethrow; // let caller catch & show error
    }

    // in v7, authentication is synchronous
    final googleAuth = googleUser.authentication;

    final authClient = _google.authorizationClient;
    final authScopes = await authClient.authorizationForScopes(['email']);

    final credential = GoogleAuthProvider.credential(
      accessToken: authScopes?.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(
      credential,
    ); // Firebase sign‑in
    await _ensureUserInFirestore(userCred.user!);
    notifyListeners();
    return userCred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _google.disconnect();
    } catch (_) {}
    notifyListeners();
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

extension on GoogleSignInException {
  get cause => null;
}
