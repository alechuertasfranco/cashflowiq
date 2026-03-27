// lib\features\auth\data\auth_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
    if (googleUser == null) throw Exception("Login cancelado");
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    await _syncUserWithBackend();
    return userCredential;
  }

  // 🔁 SYNC USER
  Future<void> _syncUserWithBackend() async {
    debugPrint('_syncUserWithBackend');
    await ApiClient.post("/auth/sync-user");
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
