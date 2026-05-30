import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static bool _isHiveInitialized = false;

  static Box? _authBox;
  static Box? _settingsBox;
  static Box? _documentsBox;
  static Box? _aiHistoryBox;

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _isHiveInitialized = true;
      print("Hive framework initialized successfully.");
    } catch (e) {
      print("CRITICAL ERROR: Failed to initialize Hive framework: $e");
      _isHiveInitialized = false;
    }

    if (_isHiveInitialized) {
      _authBox = await _openBoxSafely('auth_box');
      _settingsBox = await _openBoxSafely('settings_box');
      _documentsBox = await _openBoxSafely('documents_box');
      _aiHistoryBox = await _openBoxSafely('ai_history_box');
    }
  }

  static Future<Box?> _openBoxSafely(String boxName) async {
    try {
      return await Hive.openBox(boxName);
    } catch (e) {
      print("Failed to open Hive Box '$boxName': $e. Re-trying after clearing old lock file...");
      try {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox(boxName);
      } catch (innerError) {
        print("Fatal error opening box '$boxName': $innerError");
        return null;
      }
    }
  }

  // --- Auth & User Profile Methods ---
  
  static Future<void> saveLocalUser(String username, String password, Map<String, dynamic> profileData) async {
    try {
      final key = 'user_$username';
      final userData = {
        'username': username,
        'password': password,
        'uid': username.hashCode.toString(),
        'email': profileData['email'] ?? '$username@lexora.local',
        'displayName': profileData['displayName'] ?? username,
      };
      
      if (_authBox != null) {
        await _authBox!.put(key, userData);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, userData.toString());
      }
    } catch (e) {
      print("Error saving local user: $e");
    }
  }

  static Map<String, dynamic>? getLocalUser(String username) {
    try {
      if (_authBox != null) {
        final data = _authBox!.get('user_$username');
        if (data != null) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      print("Error getting local user: $e");
    }
    return null;
  }

  static Future<void> setCurrentUserSession(String? username) async {
    try {
      if (_authBox != null) {
        if (username == null) {
          await _authBox!.delete('current_username');
        } else {
          await _authBox!.put('current_username', username);
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        if (username == null) {
          await prefs.remove('current_username');
        } else {
          await prefs.setString('current_username', username);
        }
      }
    } catch (e) {
      print("Error setting session: $e");
    }
  }

  static String? getCurrentUserSession() {
    try {
      if (_authBox != null) {
        return _authBox!.get('current_username') as String?;
      }
    } catch (e) {
      print("Error getting session: $e");
    }
    return null;
  }

  // --- Settings & Configurations ---

  static Future<void> saveSetting(String key, dynamic value) async {
    try {
      if (_settingsBox != null) {
        await _settingsBox!.put(key, value);
      } else {
        final prefs = await SharedPreferences.getInstance();
        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        }
      }
    } catch (e) {
      print("Error saving setting $key: $e");
    }
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    try {
      if (_settingsBox != null) {
        return _settingsBox!.get(key, defaultValue: defaultValue);
      }
    } catch (e) {
      print("Error reading setting $key: $e");
    }
    return defaultValue;
  }

  // --- Documents Storage ---

  static Future<void> saveDocument(String id, Map<String, dynamic> docMap) async {
    try {
      if (_documentsBox != null) {
        await _documentsBox!.put(id, docMap);
      }
    } catch (e) {
      print("Error saving document $id: $e");
    }
  }

  static List<Map<String, dynamic>> getAllDocuments() {
    try {
      if (_documentsBox != null) {
        final docs = _documentsBox!.values;
        return docs.map((doc) => Map<String, dynamic>.from(doc)).toList();
      }
    } catch (e) {
      print("Error loading all documents: $e");
    }
    return [];
  }

  static Future<void> deleteDocument(String id) async {
    try {
      if (_documentsBox != null) {
        await _documentsBox!.delete(id);
      }
    } catch (e) {
      print("Error deleting document $id: $e");
    }
  }

  // --- AI Chat History ---

  static Future<void> saveAIChatHistory(String userId, List<Map<String, String>> messages) async {
    try {
      if (_aiHistoryBox != null) {
        await _aiHistoryBox!.put('chat_history_$userId', messages);
      }
    } catch (e) {
      print("Error saving AI history for $userId: $e");
    }
  }

  static List<Map<String, String>> getAIChatHistory(String userId) {
    try {
      if (_aiHistoryBox != null) {
        final data = _aiHistoryBox!.get('chat_history_$userId');
        if (data != null) {
          final List<dynamic> list = data;
          return list.map((item) => Map<String, String>.from(item)).toList();
        }
      }
    } catch (e) {
      print("Error loading AI history for $userId: $e");
    }
    return [];
  }
}
