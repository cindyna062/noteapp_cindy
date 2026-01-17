import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final int id;
  final String userId;
  final String title;
  final String content;
  final bool isPinned;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.isPinned,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'is_pinned': isPinned,
    };
  }

  Note copyWith({
    int? id,
    String? userId,
    String? title,
    String? content,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, title, content, isPinned, createdAt];
}
