import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import 'local_storage_service.dart';

class LocalUser {
  final String uid;
  final String email;
  final String username;

  LocalUser({
    required this.uid,
    required this.email,
    required this.username,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
    );
  }
}

final authServiceProvider = Provider<LocalAuthService>((ref) {
  return LocalAuthService();
});

final authStateProvider = StreamProvider<LocalUser?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

final guestModeProvider = StateProvider<bool>((ref) {
  // Try to load initial guest mode state
  return false;
});

class LocalAuthService {
  final StreamController<LocalUser?> _authStateController = StreamController<LocalUser?>.broadcast();
  LocalUser? _currentUser;

  LocalAuthService() {
    _initializeSession();
  }

  void _initializeSession() {
    final activeUsername = LocalStorageService.getCurrentUserSession();
    if (activeUsername != null) {
      final userData = LocalStorageService.getLocalUser(activeUsername);
      if (userData != null) {
        _currentUser = LocalUser.fromMap(userData);
        _authStateController.add(_currentUser);
      }
    }
  }

  bool get isFirebaseAvailable => true; // Kept true to satisfy UI branch checks and run standard login pathways

  Stream<LocalUser?> get authStateChanges => _authStateController.stream;

  LocalUser? get currentUser => _currentUser;

  // Sign In locally
  Future<void> signIn(String usernameOrEmail, String password) async {
    // Normalise input
    final username = usernameOrEmail.trim().toLowerCase();
    
    // Attempt to load from storage
    final userData = LocalStorageService.getLocalUser(username);
    if (userData == null) {
      throw Exception("Foydalanuvchi topilmadi. Avval ro'yxatdan o'ting.");
    }

    final storedPassword = userData['password'];
    if (storedPassword != password) {
      throw Exception("Noto'g'ri parol kiritildi.");
    }

    // Set Session
    _currentUser = LocalUser.fromMap(userData);
    await LocalStorageService.setCurrentUserSession(username);
    _authStateController.add(_currentUser);
  }

  // Register locally
  Future<void> signUp(String usernameOrEmail, String password) async {
    final username = usernameOrEmail.trim().toLowerCase();
    
    if (password.length < 6) {
      throw Exception("Parol kamida 6 belgidan iborat bo'lishi kerak.");
    }

    // Check if user already exists
    final existingUser = LocalStorageService.getLocalUser(username);
    if (existingUser != null) {
      throw Exception("Ushbu foydalanuvchi nomi allaqachon ro'yxatdan o'tgan.");
    }

    // Save profile details
    final profile = {
      'email': username.contains('@') ? username : '$username@lexora.local',
      'displayName': username.split('@').first,
    };

    await LocalStorageService.saveLocalUser(username, password, profile);
    
    // Automatically log in
    await signIn(username, password);
  }

  // Mock Password Reset
  Future<void> sendPasswordReset(String email) async {
    final username = email.trim().toLowerCase();
    final user = LocalStorageService.getLocalUser(username);
    if (user == null) {
      throw Exception("Kiritilgan email/foydalanuvchi bo'yicha hisob topilmadi.");
    }
    // Simulation success
    await Future.delayed(const Duration(milliseconds: 800));
  }

  // Log Out locally
  Future<void> signOut(WidgetRef ref) async {
    ref.read(guestModeProvider.notifier).state = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyGuestMode, false);

    if (_currentUser != null) {
      await LocalStorageService.setCurrentUserSession(null);
      _currentUser = null;
    }
    _authStateController.add(null);
  }

  // Guest Mode login
  Future<void> loginAsGuest(WidgetRef ref) async {
    ref.read(guestModeProvider.notifier).state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyGuestMode, true);
    
    // Clear user session when switching to guest mode
    if (_currentUser != null) {
      await LocalStorageService.setCurrentUserSession(null);
      _currentUser = null;
    }
    _authStateController.add(null);
  }
}
