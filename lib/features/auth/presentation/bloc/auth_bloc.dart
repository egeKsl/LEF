import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/matrix_auth_service.dart';

// --- Events ---
abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String node;
  final String username;
  final String password;
  LoginRequested({required this.node, required this.username, required this.password});
}

class RegisterRequested extends AuthEvent {
  final String node;
  final String username;
  final String password;
  RegisterRequested({required this.node, required this.username, required this.password});
}

class LogoutRequested extends AuthEvent {}

// --- States ---
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final String userId;
  AuthSuccess(this.userId);
}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}
class Unauthenticated extends AuthState {}

// --- Bloc Implementation ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final MatrixAuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final userId = await _authService.login(
          homeserver: event.node,
          username: event.username,
          password: event.password,
        );
        emit(AuthSuccess(userId));
      } catch (e) {
        emit(AuthFailure(_cleanErrorMessage(e.toString())));
      }
    });

    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final userId = await _authService.register(
          homeserver: event.node,
          username: event.username,
          password: event.password,
        );
        emit(AuthSuccess(userId));
      } catch (e) {
        emit(AuthFailure(_cleanErrorMessage(e.toString())));
      }
    });

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _authService.logout();
        emit(Unauthenticated());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }

  String _cleanErrorMessage(String rawError) {
    if (rawError.contains("M_USER_IN_USE")) {
      return "ERROR: IDENTITY_ALREADY_EXISTS // Selected username is already taken.";
    } else if (rawError.contains("M_FORBIDDEN")) {
      return "ERROR: INVALID_CREDENTIALS // Invalid credentials.";
    } else if (rawError.contains("SocketException")) {
      return "ERROR: NET_NODE_UNREACHABLE // Unable to connect to the server.";
    }
    return "ERROR: SECURE_LINK_FAILED // $rawError";
  }
}