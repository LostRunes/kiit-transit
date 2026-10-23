import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/datasources/transit_source.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repo) {
    _sub = _repo.userChanges.listen((user) {
      _user = user;
      _status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
      notifyListeners();
    });
  }

  final AuthRepository _repo;
  late final StreamSubscription<UserModel?> _sub;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _busy = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get busy => _busy;
  String? get error => _error;
  bool get isSignedIn => _status == AuthStatus.signedIn && _user != null;

  Future<void> restore() async {
    try {
      _user = await _repo.restoreSession();
    } catch (_) {
      _user = null;
    }
    _status = _user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) => _run(() async => _user = await _repo.signIn(email, password));

  /// Returns true when signed in straight away; false with [pendingConfirmation]
  /// set when the backend requires email confirmation first.
  bool pendingConfirmation = false;

  Future<bool> signUp({required String name, required String email, required String password, String? phone}) => _run(() async {
    final user = await _repo.signUp(name: name, email: email, password: password, phone: phone);
    pendingConfirmation = user == null;
    _user = user;
  });

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<bool> updateProfile({required String name, String? phone}) =>
      _run(() async => _user = await _repo.updateProfile(name: name, phone: phone));

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      if (_user != null) _status = AuthStatus.signedIn;
      return true;
    } on AuthFailure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Something went wrong. Check your connection and try again.';
      debugPrint('Auth error: $e');
    } finally {
      _busy = false;
      notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
