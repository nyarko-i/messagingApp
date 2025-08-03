import 'package:flutter/foundation.dart'; // <— add this
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  // <— extend ChangeNotifier
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  AuthService() {
    _google.initialize().catchError((_) {});
  }

  Future<void> signInWithGoogle() async {
    final acc = await _google.authenticate(scopeHint: ['email']);
    final auth = acc.authentication;
    final cred = GoogleAuthProvider.credential(idToken: auth.idToken);
    await _auth.signInWithCredential(cred);
    notifyListeners(); // <— add if you want to reflect changes
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _auth.signOut();
    notifyListeners(); // <— add if needed
  }

  Future<void> signInWithEmail(String email, String pass) async {
    await _auth.signInWithEmailAndPassword(email: email, password: pass);
    notifyListeners();
  }

  Future<void> signUpWithEmail(String email, String pass) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: pass);
    notifyListeners();
  }
}
