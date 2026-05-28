import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'document_model.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../core/constants/app_constants.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref);
});

final documentListProvider = StateNotifierProvider<DocumentListNotifier, List<DocumentModel>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentListNotifier(repository);
});

class DocumentRepository {
  final Ref _ref;
  FirebaseFirestore? _firestore;

  DocumentRepository(this._ref) {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (_) {
      _firestore = null;
    }
  }

  bool get isFirestoreAvailable => _firestore != null;

  String _getUserId() {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) return user.uid;
    
    final isGuest = _ref.read(guestModeProvider);
    if (isGuest) return 'guest_user';
    
    return 'anonymous';
  }

  // Load documents from either local storage or cloud
  Future<List<DocumentModel>> loadDocuments() async {
    final userId = _getUserId();
    
    // Always start by reading local cache first (Offline first!)
    final localDocs = await _loadFromLocal();
    final userDocs = localDocs.where((doc) => doc.userId == userId).toList();

    if (!isFirestoreAvailable || userId == 'guest_user' || userId == 'anonymous') {
      return userDocs;
    }

    try {
      // Fetch from Firestore
      final snapshot = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('documents')
          .orderBy('lastModified', descending: true)
          .get();

      final remoteDocs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // ensure ID matches doc ID
        return DocumentModel.fromMap(data).copyWith(isSynced: true);
      }).toList();

      // Merge remote and local (remote takes precedence, write missing back to local)
      if (remoteDocs.isNotEmpty) {
        await _saveMultipleToLocal(remoteDocs);
        return remoteDocs;
      }
    } catch (e) {
      print("Firestore load failed, returning local cache: $e");
    }

    return userDocs;
  }

  // Save single document (Auto-save)
  Future<void> saveDocument(DocumentModel doc) async {
    final userId = _getUserId();
    final updatedDoc = doc.copyWith(userId: userId, lastModified: DateTime.now());

    // 1. Save to local storage first (instant responsiveness)
    await _saveToLocal(updatedDoc);

    // 2. Sync to cloud asynchronously if online
    if (isFirestoreAvailable && userId != 'guest_user' && userId != 'anonymous') {
      try {
        await _firestore!
            .collection('users')
            .doc(userId)
            .collection('documents')
            .doc(updatedDoc.id)
            .set(updatedDoc.toMap());
        
        // Update local state flag to synced
        await _saveToLocal(updatedDoc.copyWith(isSynced: true));
      } catch (e) {
        print("Firestore auto-save sync failed: $e. Saved locally.");
      }
    }
  }

  // Delete Document
  Future<void> deleteDocument(String docId) async {
    final userId = _getUserId();

    // 1. Remove from local cache
    final localDocs = await _loadFromLocal();
    localDocs.removeWhere((doc) => doc.id == docId);
    await _saveAllToLocal(localDocs);

    // 2. Remove from Firestore
    if (isFirestoreAvailable && userId != 'guest_user' && userId != 'anonymous') {
      try {
        await _firestore!
            .collection('users')
            .doc(userId)
            .collection('documents')
            .doc(docId)
            .delete();
      } catch (e) {
        print("Firestore delete failed: $e");
      }
    }
  }

  // Local helper: Load all docs from SharedPreferences
  Future<List<DocumentModel>> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(AppConstants.keyRecentDocs);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decodedList = json.decode(jsonString);
      return decodedList.map((item) => DocumentModel.fromMap(item)).toList();
    } catch (e) {
      print("Error decoding local documents cache: $e");
      return [];
    }
  }

  // Local helper: Save a single doc to cache
  Future<void> _saveToLocal(DocumentModel newDoc) async {
    final list = await _loadFromLocal();
    final idx = list.indexWhere((doc) => doc.id == newDoc.id);
    if (idx != -1) {
      list[idx] = newDoc;
    } else {
      list.insert(0, newDoc);
    }
    await _saveAllToLocal(list);
  }

  // Local helper: Save multiple docs
  Future<void> _saveMultipleToLocal(List<DocumentModel> docs) async {
    final list = await _loadFromLocal();
    for (var doc in docs) {
      final idx = list.indexWhere((d) => d.id == doc.id);
      if (idx != -1) {
        list[idx] = doc;
      } else {
        list.add(doc);
      }
    }
    await _saveAllToLocal(list);
  }

  // Local helper: Overwrite entire list
  Future<void> _saveAllToLocal(List<DocumentModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    // Sort before saving locally to keep consistent ordering
    list.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    final encoded = json.encode(list.map((doc) => doc.toMap()).toList());
    await prefs.setString(AppConstants.keyRecentDocs, encoded);
  }
}

class DocumentListNotifier extends StateNotifier<List<DocumentModel>> {
  final DocumentRepository _repository;

  DocumentListNotifier(this._repository) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repository.loadDocuments();
  }

  Future<void> save(DocumentModel doc) async {
    await _repository.saveDocument(doc);
    
    // Update local state instantly so listeners rebuild
    final idx = state.indexWhere((d) => d.id == doc.id);
    if (idx != -1) {
      final updatedList = List<DocumentModel>.from(state);
      updatedList[idx] = doc.copyWith(lastModified: DateTime.now());
      updatedList.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      state = updatedList;
    } else {
      state = [doc.copyWith(lastModified: DateTime.now()), ...state];
    }
  }

  Future<void> delete(String docId) async {
    await _repository.deleteDocument(docId);
    state = state.where((doc) => doc.id != docId).toList();
  }

  Future<void> rename(String docId, String newTitle) async {
    final idx = state.indexWhere((doc) => doc.id == docId);
    if (idx != -1) {
      final doc = state[idx].copyWith(title: newTitle);
      await save(doc);
    }
  }
}
