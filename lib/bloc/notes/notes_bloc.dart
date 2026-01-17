import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/supabase_service.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final SupabaseService _supabaseService;
  StreamSubscription? _notesSubscription;

  NotesBloc({required SupabaseService supabaseService})
    : _supabaseService = supabaseService,
      super(const NotesState()) {
    on<NotesLoadRequested>(_onLoadRequested);
    on<NotesStreamUpdated>(_onStreamUpdated);
    on<NoteAddRequested>(_onAddRequested);
    on<NoteUpdateRequested>(_onUpdateRequested);
    on<NoteDeleteRequested>(_onDeleteRequested);
    on<NotePinToggled>(_onPinToggled);
    on<NotesSearchQueryChanged>(_onSearchQueryChanged);
  }

  Future<void> _onLoadRequested(
    NotesLoadRequested event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading));

    // Cancel any existing subscription
    await _notesSubscription?.cancel();

    // Check if user is authenticated before setting up stream
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      // User not authenticated, show empty state but don't error
      emit(state.copyWith(status: NotesStatus.success, notes: []));
      return;
    }

    // Set up the real-time stream
    _notesSubscription = _supabaseService.getNotesStream().listen(
      (notes) {
        add(NotesStreamUpdated(notes));
      },
      onError: (error) {
        // On error, try to fetch notes directly as fallback
        _fetchNotesFallback();
      },
    );

    // Also fetch notes immediately to ensure we have data
    await _fetchNotesFallback();
  }

  Future<void> _fetchNotesFallback() async {
    try {
      final notes = await _supabaseService.fetchNotes();
      add(NotesStreamUpdated(notes));
    } catch (e) {
      // Ignore fallback errors, stream will handle it
    }
  }

  void _onStreamUpdated(NotesStreamUpdated event, Emitter<NotesState> emit) {
    emit(state.copyWith(status: NotesStatus.success, notes: event.notes));
  }

  Future<void> _onAddRequested(
    NoteAddRequested event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _supabaseService.addNote(
        title: event.title,
        content: event.content,
        isPinned: event.isPinned,
      );
      // Manually refresh to ensure auto-update
      await _fetchNotesFallback();
    } catch (e) {
      emit(
        state.copyWith(
          status: NotesStatus.error,
          errorMessage: 'Failed to add note: $e',
        ),
      );
    }
  }

  Future<void> _onUpdateRequested(
    NoteUpdateRequested event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _supabaseService.updateNote(
        id: event.id,
        title: event.title,
        content: event.content,
        isPinned: event.isPinned,
      );
      // Manually refresh to ensure auto-update
      await _fetchNotesFallback();
    } catch (e) {
      emit(
        state.copyWith(
          status: NotesStatus.error,
          errorMessage: 'Failed to update note: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    NoteDeleteRequested event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _supabaseService.deleteNote(event.id);
      // Manually refresh to ensure auto-update
      await _fetchNotesFallback();
    } catch (e) {
      emit(
        state.copyWith(
          status: NotesStatus.error,
          errorMessage: 'Failed to delete note: $e',
        ),
      );
    }
  }

  Future<void> _onPinToggled(
    NotePinToggled event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _supabaseService.togglePin(event.note);
      // Manually refresh to ensure auto-update
      await _fetchNotesFallback();
    } catch (e) {
      emit(
        state.copyWith(
          status: NotesStatus.error,
          errorMessage: 'Failed to toggle pin: $e',
        ),
      );
    }
  }

  void _onSearchQueryChanged(
    NotesSearchQueryChanged event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  @override
  Future<void> close() {
    _notesSubscription?.cancel();
    return super.close();
  }
}
