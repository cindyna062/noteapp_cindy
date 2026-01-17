import 'package:equatable/equatable.dart';
import '../../models/note.dart';

enum NotesStatus { initial, loading, success, error }

class NotesState extends Equatable {
  final NotesStatus status;
  final List<Note> notes;
  final String searchQuery;
  final String? errorMessage;

  const NotesState({
    this.status = NotesStatus.initial,
    this.notes = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  List<Note> get filteredNotes {
    if (searchQuery.isEmpty) {
      return notes;
    }
    final query = searchQuery.toLowerCase();
    return notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();
  }

  List<Note> get pinnedNotes => filteredNotes.where((n) => n.isPinned).toList();
  List<Note> get unpinnedNotes =>
      filteredNotes.where((n) => !n.isPinned).toList();

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? notes,
    String? searchQuery,
    String? errorMessage,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, notes, searchQuery, errorMessage];
}
