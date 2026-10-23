import '../datasources/transit_source.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._source);

  final TransitSource _source;

  UserModel? get currentUser => _source.currentUser;

  Stream<UserModel?> get userChanges => _source.userChanges;

  Future<UserModel?> restoreSession() => _source.restoreSession();

  Future<UserModel> signIn(String email, String password) => _source.signIn(email: email, password: password);

  Future<UserModel?> signUp({required String name, required String email, required String password, String? phone}) =>
      _source.signUp(name: name, email: email, password: password, phone: phone);

  Future<void> signOut() => _source.signOut();

  Future<UserModel> updateProfile({required String name, String? phone}) => _source.updateProfile(name: name, phone: phone);
}
