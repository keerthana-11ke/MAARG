import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Safe Firebase check
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseAuthRepository(FirebaseAuth.instance);
    }
  } catch (e) {
    print('Firebase not initialized. Defaulting to MockAuthRepository: $e');
  }
  return MockAuthRepository();
});

final authStateProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});
