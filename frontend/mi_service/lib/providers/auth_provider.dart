import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _loadStoredUser();
  }

  final _api = ApiService();

  Future<void> _loadStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        state = state.copyWith(user: user);
      }
    } catch (e) {
      print('Error cargando usuario: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.login(email, password);
      
      // Ajuste según la estructura real de tu API
      final user = User(
        id: data['id'] ?? 0,
        nombre: data['nombre'] ?? '',
        email: data['email'] ?? email,
        rol: data['rol'] ?? 'conductor',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      await prefs.setString('token', data['token'] ?? '');

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    state = AuthState();
  }
}