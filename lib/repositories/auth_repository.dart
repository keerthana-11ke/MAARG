import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<String?> signInAnonymously();
  Future<void> signOut();
  String? get currentUserId;
  Stream<String?> get authStateChanges;
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepository(this._auth);

  @override
  Future<String?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user?.uid;
    } catch (e) {
      print('Firebase Auth Error: $e. Falling back to mock authentication.');
      return 'mock_firebase_user_id';
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);
}

class MockAuthRepository implements AuthRepository {
  final StreamController<String?> _authController = StreamController<String?>.broadcast();
  String? _userId;

  MockAuthRepository() {
    _authController.add(null);
  }

  @override
  Future<String?> signInAnonymously() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _userId = 'mock_bystander_${DateTime.now().millisecondsSinceEpoch % 1000}';
    _authController.add(_userId);
    return _userId;
  }

  @override
  Future<void> signOut() async {
    _userId = null;
    _authController.add(null);
  }

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> get authStateChanges => _authController.stream;
}
