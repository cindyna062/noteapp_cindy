import 'package:equatable/equatable.dart';
import '../../models/note.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

class NotesLoadRequested extends NotesEvent {}

class NotesStreamUpdated extends NotesEvent {
  final List<Note> notes;

  const NotesStreamUpdated(this.notes);

  @override
  List<Object?> get props => [notes];
}

class NoteAddRequested extends NotesEvent {
  final String title;
  final String content;
  final bool isPinned;

  const NoteAddRequested({
    required this.title,
    required this.content,
    this.isPinned = false,
  });

  @override
  List<Object?> get props => [title, content, isPinned];
}

class NoteUpdateRequested extends NotesEvent {
  final int id;
  final String title;
  final String content;
  final bool isPinned;

  const NoteUpdateRequested({
    required this.id,
    required this.title,
    required this.content,
    required this.isPinned,
  });

  @override
  List<Object?> get props => [id, title, content, isPinned];
}

class NoteDeleteRequested extends NotesEvent {
  final int id;

  const NoteDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class NotePinToggled extends NotesEvent {
  final Note note;

  const NotePinToggled(this.note);

  @override
  List<Object?> get props => [note];
}

class NotesSearchQueryChanged extends NotesEvent {
  final String query;

  const NotesSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}
