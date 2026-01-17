import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../services/supabase_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AppAuthState> {
  final SupabaseService _supabaseService;
  StreamSubscription? _authStateSubscription;

  AuthBloc({required SupabaseService supabaseService})
    : _supabaseService = supabaseService,
      super(const AppAuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<_AuthStateChanged>(_onAuthStateChanged);

    // Listen to auth state changes and dispatch internal event
    _authStateSubscription = _supabaseService.authStateChanges.listen((
      authState,
    ) {
      final session = authState.session;
      add(_AuthStateChanged(session: session));
    });
  }

  void _onAuthStateChanged(
    _AuthStateChanged event,
    Emitter<AppAuthState> emit,
  ) {
    if (event.session != null) {
      emit(
        AppAuthState(
          status: AppAuthStatus.authenticated,
          userId: event.session!.user.id,
          email: event.session!.user.email,
        ),
      );
    } else {
      emit(const AppAuthState(status: AppAuthStatus.unauthenticated));
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      emit(
        AppAuthState(
          status: AppAuthStatus.authenticated,
          userId: session.user.id,
          email: session.user.email,
        ),
      );
    } else {
      emit(const AppAuthState(status: AppAuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(state.copyWith(status: AppAuthStatus.loading));

    try {
      final response = await _supabaseService.signUp(
        email: event.email,
        password: event.password,
      );

      // Check for session first - if no session, user needs to confirm email
      if (response.session != null) {
        emit(
          AppAuthState(
            status: AppAuthStatus.authenticated,
            userId: response.user!.id,
            email: response.user!.email,
          ),
        );
      } else if (response.user != null) {
        // User created but no session - email confirmation required
        emit(
          state.copyWith(
            status: AppAuthStatus.error,
            errorMessage:
                'Please check your email to confirm your account, then sign in.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AppAuthStatus.error,
            errorMessage: 'Sign up failed. Please try again.',
          ),
        );
      }
    } on AuthException catch (e) {
      emit(
        state.copyWith(status: AppAuthStatus.error, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AppAuthStatus.error,
          errorMessage: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(state.copyWith(status: AppAuthStatus.loading));

    try {
      final response = await _supabaseService.signIn(
        email: event.email,
        password: event.password,
      );

      if (response.user != null) {
        emit(
          AppAuthState(
            status: AppAuthStatus.authenticated,
            userId: response.user!.id,
            email: response.user!.email,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AppAuthStatus.error,
            errorMessage: 'Sign in failed. Please check your credentials.',
          ),
        );
      }
    } on AuthException catch (e) {
      emit(
        state.copyWith(status: AppAuthStatus.error, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AppAuthStatus.error,
          errorMessage: 'An unexpected error occurred.',
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(state.copyWith(status: AppAuthStatus.loading));

    try {
      await _supabaseService.signOut();
      emit(const AppAuthState(status: AppAuthStatus.unauthenticated));
    } catch (e) {
      emit(
        state.copyWith(
          status: AppAuthStatus.error,
          errorMessage: 'Sign out failed. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

// Internal event for auth state changes from Supabase stream
class _AuthStateChanged extends AuthEvent {
  final Session? session;

  const _AuthStateChanged({this.session});

  @override
  List<Object?> get props => [session];
}
