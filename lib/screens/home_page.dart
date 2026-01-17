import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/notes/notes_bloc.dart';
import '../bloc/notes/notes_event.dart';
import '../bloc/notes/notes_state.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';
import '../widgets/empty_state.dart';
import 'add_edit_note_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<NotesBloc>().add(NotesLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddNote() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditNotePage()),
    );
  }

  void _navigateToEditNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditNotePage(note: note)),
    );
  }

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                ),
                title: Text(note.isPinned ? 'Unpin note' : 'Pin note'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<NotesBloc>().add(NotePinToggled(note));
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit note'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditNote(note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outlined, color: Colors.red),
                title: const Text(
                  'Delete note',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(note);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotesBloc>().add(NoteDeleteRequested(note.id));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  if (!_isSearching) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Notes',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 4),
                          BlocBuilder<NotesBloc, NotesState>(
                            builder: (context, state) {
                              final count = state.notes.length;
                              return Text(
                                '$count ${count == 1 ? 'note' : 'notes'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                        onChanged: (value) {
                          context.read<NotesBloc>().add(
                            NotesSearchQueryChanged(value),
                          );
                        },
                      ),
                    ),
                  ],
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          context.read<NotesBloc>().add(
                            const NotesSearchQueryChanged(''),
                          );
                        }
                      });
                    },
                    icon: Icon(_isSearching ? Icons.close : Icons.search),
                  ),
                  IconButton(
                    onPressed: _showLogoutConfirmation,
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
            ),

            // Notes Grid
            Expanded(
              child: BlocBuilder<NotesBloc, NotesState>(
                builder: (context, state) {
                  if (state.status == NotesStatus.loading &&
                      state.notes.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == NotesStatus.error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage ?? 'An error occurred',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {
                              context.read<NotesBloc>().add(
                                NotesLoadRequested(),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final pinnedNotes = state.pinnedNotes;
                  final unpinnedNotes = state.unpinnedNotes;

                  if (pinnedNotes.isEmpty && unpinnedNotes.isEmpty) {
                    return EmptyState(
                      title: state.searchQuery.isNotEmpty
                          ? 'No notes found'
                          : 'No notes yet',
                      subtitle: state.searchQuery.isNotEmpty
                          ? 'Try a different search term'
                          : 'Tap the + button to create your first note',
                      icon: state.searchQuery.isNotEmpty
                          ? Icons.search_off
                          : Icons.note_add_outlined,
                      onActionPressed: state.searchQuery.isEmpty
                          ? _navigateToAddNote
                          : null,
                      actionLabel: state.searchQuery.isEmpty
                          ? 'Create Note'
                          : null,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<NotesBloc>().add(NotesLoadRequested());
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Pinned Notes Section
                        if (pinnedNotes.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.push_pin, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pinned',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverMasonryGrid.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childCount: pinnedNotes.length,
                              itemBuilder: (context, index) {
                                final note = pinnedNotes[index];
                                return NoteCard(
                                  note: note,
                                  colorIndex: note.id,
                                  onTap: () => _navigateToEditNote(note),
                                  onLongPress: () => _showNoteOptions(note),
                                  onPinTap: () {
                                    context.read<NotesBloc>().add(
                                      NotePinToggled(note),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],

                        // Unpinned Notes Section
                        if (unpinnedNotes.isNotEmpty) ...[
                          if (pinnedNotes.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  8,
                                ),
                                child: Text(
                                  'Others',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ),
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverMasonryGrid.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childCount: unpinnedNotes.length,
                              itemBuilder: (context, index) {
                                final note = unpinnedNotes[index];
                                return NoteCard(
                                  note: note,
                                  colorIndex: note.id,
                                  onTap: () => _navigateToEditNote(note),
                                  onLongPress: () => _showNoteOptions(note),
                                  onPinTap: () {
                                    context.read<NotesBloc>().add(
                                      NotePinToggled(note),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],

                        // Bottom padding
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddNote,
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
      ),
    );
  }
}
