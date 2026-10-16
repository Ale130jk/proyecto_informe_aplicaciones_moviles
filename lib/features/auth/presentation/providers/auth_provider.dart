import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  AuthState({this.isLoading = false, this.errorMessage, this.isAuthenticated = false});

  AuthState copyWith({bool? isLoading, String? errorMessage, bool? isAuthenticated}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, 
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState();

  Future<bool> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      state = state.copyWith(errorMessage: 'Complete todos los campos');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = ref.read(authRepositoryProvider);
      final isValid = await repository.validateAdminCredentials(username, password);

      if (isValid) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Usuario o contraseña incorrectos');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error de red. Verifique su conexión.');
      return false;
    }
  }
}