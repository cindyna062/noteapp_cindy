import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get current user ID - check both currentUser and currentSession
  String? get currentUserId {
    // Try currentUser first
    final user = _client.auth.currentUser;
    if (user != null) {
      return user.id;
    }
    // Fallback to currentSession
    final session = _client.auth.currentSession;
    return session?.user.id;
  }

  // Stream of notes for the current user (pinned first, then by created_at desc)
  Stream<List<Note>> getNotesStream() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _client
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Note.fromJson(json)).toList());
  }

  // Fetch all notes for the current user
  Future<List<Note>> fetchNotes() async {
    final userId = currentUserId;
    if (userId == null) {
      return [];
    }

    final response = await _client
        .from('notes')
        .select()
        .eq('user_id', userId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Note.fromJson(json)).toList();
  }

  // Add a new note
  Future<Note> addNote({
    required String title,
    required String content,
    bool isPinned = false,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      // Provide more detailed error for debugging
      final hasUser = _client.auth.currentUser != null;
      final hasSession = _client.auth.currentSession != null;
      throw Exception(
        'User not authenticated (user: $hasUser, session: $hasSession). Please sign in again.',
      );
    }

    final response = await _client
        .from('notes')
        .insert({
          'user_id': userId,
          'title': title,
          'content': content,
          'is_pinned': isPinned,
        })
        .select()
        .single();

    return Note.fromJson(response);
  }

  // Update an existing note
  Future<Note> updateNote({
    required int id,
    required String title,
    required String content,
    required bool isPinned,
  }) async {
    final response = await _client
        .from('notes')
        .update({'title': title, 'content': content, 'is_pinned': isPinned})
        .eq('id', id)
        .select()
        .single();

    return Note.fromJson(response);
  }

  // Delete a note
  Future<void> deleteNote(int id) async {
    await _client.from('notes').delete().eq('id', id);
  }

  // Toggle pin status
  Future<Note> togglePin(Note note) async {
    return updateNote(
      id: note.id,
      title: note.title,
      content: note.content,
      isPinned: !note.isPinned,
    );
  }

  // Auth methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
