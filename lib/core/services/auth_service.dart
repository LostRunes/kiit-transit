import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper over Supabase Auth so the rest of the app never touches the
/// SDK's auth client directly.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) => _auth.signInWithPassword(email: email, password: password);

  /// `name` and `phone` travel as user metadata; the `handle_new_user`
  /// trigger copies them into `profiles`.
  Future<AuthResponse> signUp(String email, String password, {required String name, String? phone}) =>
      _auth.signUp(email: email, password: password, data: {'name': name, 'phone': phone});

  Future<void> signOut() => _auth.signOut();
}
