import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register with email, password, and display name
  Future<User?> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set display name
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();

      // Save user profile to Firestore
      if (credential.user != null) {
        await _saveUserProfile(credential.user!, name);
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e.code);
    }
  }

  /// Sign in with email and password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e.code);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e.code);
    }
  }

  /// Sign in with Google (one-click) — uses google_sign_in v6 API
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Save user profile to Firestore (first time)
      if (userCredential.user != null) {
        await _saveUserProfile(
          userCredential.user!,
          userCredential.user!.displayName ?? 'User',
        );
      }

      return userCredential.user;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Get display name from Firestore (more reliable than FirebaseAuth profile)
  Future<String> getDisplayName() async {
    final user = _auth.currentUser;
    if (user == null) return 'User';

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['name'] != null) {
        return doc.data()!['name'];
      }
    } catch (_) {}

    return user.displayName ?? user.email?.split('@').first ?? 'User';
  }

  /// Update user profile name
  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(newName);
      await _saveUserProfile(user, newName);
    }
  }

  /// Save user profile to Firestore
  Future<void> _saveUserProfile(User user, String name) async {
    await _db.collection('users').doc(user.uid).set({
      'name': name,
      'email': user.email ?? '',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Map Firebase error codes to Indonesian messages
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan: $code';
    }
  }
}
