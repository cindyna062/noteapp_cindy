import 'package:equatable/equatable.dart';

enum AppAuthStatus { initial, loading, authenticated, unauthenticated, error }

class AppAuthState extends Equatable {
  final AppAuthStatus status;
  final String? userId;
  final String? email;
  final String? errorMessage;

  const AppAuthState({
    this.status = AppAuthStatus.initial,
    this.userId,
    this.email,
    this.errorMessage,
  });

  AppAuthState copyWith({
    AppAuthStatus? status,
    String? userId,
    String? email,
    String? errorMessage,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, userId, email, errorMessage];
}
