import 'dart:convert';

class DocumentModel {
  final String id;
  final String title;
  final String content;
  final String userId;
  final DateTime lastModified;
  final bool isSynced;

  DocumentModel({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.lastModified,
    this.isSynced = false,
  });

  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  int get charCount => content.length;

  DocumentModel copyWith({
    String? id,
    String? title,
    String? content,
    String? userId,
    DateTime? lastModified,
    bool? isSynced,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'userId': userId,
      'lastModified': lastModified.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Document',
      content: map['content'] ?? '',
      userId: map['userId'] ?? '',
      lastModified: map['lastModified'] != null 
          ? DateTime.parse(map['lastModified']) 
          : DateTime.now(),
      isSynced: map['isSynced'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory DocumentModel.fromJson(String source) => DocumentModel.fromMap(json.decode(source));
}
