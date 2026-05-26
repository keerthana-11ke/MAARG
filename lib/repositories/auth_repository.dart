import 'dart:async';

abstract class AuthRepository {
  Future<String?> signInAnonymously();
  Future<void> signOut();
  String? get currentUserId;
  Stream<String?> get authStateChanges;
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
