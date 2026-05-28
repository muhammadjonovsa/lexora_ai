import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

final guestModeProvider = StateProvider<bool>((ref) => false);

class FirebaseAuthService {
  final FirebaseAuth? _auth;
  bool _isFirebaseAvailable = false;

  FirebaseAuthService() : _auth = _initAuth() {
    _isFirebaseAvailable = _auth != null;
  }

  static FirebaseAuth? _initAuth() {
    try {
      // Check if Firebase is initialized
      return FirebaseAuth.instance;
    } catch (e) {
      print("Firebase Auth not initialized: $e. Falling back to Local/Guest Mode.");
      return null;
    }
  }

  bool get isFirebaseAvailable => _isFirebaseAvailable;

  Stream<User?> get authStateChanges {
    if (_isFirebaseAvailable && _auth != null) {
      return _auth.authStateChanges();
    }
    return Stream.value(null);
  }

  User? get currentUser {
    if (_isFirebaseAvailable && _auth != null) {
      return _auth.currentUser;
    }
    return null;
  }

  // Sign In with email and password
  Future<UserCredential?> signIn(String email, String password) async {
    if (!_isFirebaseAvailable || _auth == null) {
      throw Exception("Firebase is not initialized. Please use Guest Mode.");
    }
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential?> signUp(String email, String password) async {
    if (!_isFirebaseAvailable || _auth == null) {
      throw Exception("Firebase is not initialized. Please use Guest Mode.");
    }
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  // Forgot password
  Future<void> sendPasswordReset(String email) async {
    if (!_isFirebaseAvailable || _auth == null) {
      throw Exception("Firebase is not initialized. Please use Guest Mode.");
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  // Log out
  Future<void> signOut(WidgetRef ref) async {
    ref.read(guestModeProvider.notifier).state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyGuestMode, false);
    
    if (_isFirebaseAvailable && _auth != null) {
      await _auth.signOut();
    }
  }

  // Guest login
  Future<void> loginAsGuest(WidgetRef ref) async {
    ref.read(guestModeProvider.notifier).state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyGuestMode, true);
  }

  // Parse errors
  Exception _parseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception("Ushbu email bilan foydalanuvchi topilmadi."); // translation in Uzbek
      case 'wrong-password':
        return Exception("Noto'g'ri parol kiritildi.");
      case 'email-already-in-use':
        return Exception("Ushbu email allaqachon ro'yxatdan o'tgan.");
      case 'invalid-email':
        return Exception("Email manzili noto'g'ri formatda.");
      case 'weak-password':
        return Exception("Parol juda kuchsiz (kamida 6 ta belgi bo'lishi kerak).");
      default:
        return Exception(e.message ?? "Tizimda xatolik yuz berdi. Qayta urinib ko'ring.");
    }
  }
}
