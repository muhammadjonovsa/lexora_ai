import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'document_model.dart';
import '../../../services/local_auth_service.dart';
import '../../../services/local_storage_service.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref);
});

final documentListProvider = StateNotifierProvider<DocumentListNotifier, List<DocumentModel>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentListNotifier(repository);
});

class DocumentRepository {
  final Ref _ref;

  DocumentRepository(this._ref);

  bool get isFirestoreAvailable => false; // Fully offline-only application

  String _getUserId() {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) return user.uid;
    
    final isGuest = _ref.read(guestModeProvider);
    if (isGuest) return 'guest_user';
    
    return 'anonymous';
  }

  // Load documents from Hive storage
  Future<List<DocumentModel>> loadDocuments() async {
    try {
      final userId = _getUserId();
      final allDocsList = LocalStorageService.getAllDocuments();
      
      final List<DocumentModel> userDocs = allDocsList
          .map((item) => DocumentModel.fromMap(item))
          .where((doc) => doc.userId == userId)
          .toList();
          
      // Sort by last modified date (newest first)
      userDocs.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return userDocs;
    } catch (e) {
      print("Error loading documents: $e");
      return [];
    }
  }

  // Save single document locally
  Future<void> saveDocument(DocumentModel doc) async {
    try {
      final userId = _getUserId();
      final updatedDoc = doc.copyWith(
        userId: userId, 
        lastModified: DateTime.now(),
        isSynced: false, // Local-only documents
      );

      await LocalStorageService.saveDocument(updatedDoc.id, updatedDoc.toMap());
    } catch (e) {
      print("Error saving document: $e");
    }
  }

  // Delete Document locally
  Future<void> deleteDocument(String docId) async {
    try {
      await LocalStorageService.deleteDocument(docId);
    } catch (e) {
      print("Error deleting document: $e");
    }
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
      updatedList[idx] = doc.copyWith(lastModified: DateTime.now(), isSynced: false);
      updatedList.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      state = updatedList;
    } else {
      state = [doc.copyWith(lastModified: DateTime.now(), isSynced: false), ...state];
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
