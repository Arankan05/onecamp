
enum AuthStatus {
  initial,
  loading,
  success,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  // Initial state
  factory AuthState.initial() {
    return const AuthState();
  }

  // Loading state
  factory AuthState.loading() {
    return const AuthState(status: AuthStatus.loading);
  }

  // Success state
  factory AuthState.success() {
    return const AuthState(status: AuthStatus.success);
  }

  // Error state
  factory AuthState.error(String message) {
    return AuthState(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }
}
