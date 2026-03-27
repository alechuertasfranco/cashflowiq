import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // 🔐 LOGIN EMAIL/PASSWORD
  Future<UserCredential> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);

    await _syncUserWithBackend();

    return credential;
  }

  // 🆕 REGISTER
  Future<UserCredential> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

    await _syncUserWithBackend();

    return credential;
  }

  // 🔵 GOOGLE LOGIN
  Future<UserCredential> loginWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw Exception("Login cancelado");
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

    final userCredential = await _auth.signInWithCredential(credential);

    await _syncUserWithBackend();

    return userCredential;
  }

  // 🔁 SYNC USER
  Future<void> _syncUserWithBackend() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final token = await user.getIdToken(true); // 👈 fuerza refresh (importante)

    final response = await http.post(Uri.parse("http://127.0.0.1:8000/auth/sync-user"), headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"});

    if (response.statusCode != 200) {
      throw Exception("Error syncing user: ${response.body}");
    }
  }

  // 🚪 LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
