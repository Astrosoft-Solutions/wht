import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../reminders/reminder_service.dart';
import '../data/auth_repository.dart';
import '../data/user.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

/// Holds the signed-in user; `null` means signed out.
class AuthController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _tokens => ref.read(tokenStorageProvider);

  bool _googleInitialized = false;

  @override
  Future<AppUser?> build() async {
    final sub = _tokens.onCleared.listen((reason) {
      if (reason != null && state.value != null) ref.read(sessionNoticeProvider.notifier).show(reason);
      state = const AsyncData(null);
      // A signed-out device must not keep reminding about the previous user's habits.
      ReminderService.instance.clear();
    });
    ref.onDispose(sub.cancel);

    final token = await _tokens.read();
    if (token == null) return null;
    try {
      final user = await _repo.me();
      if (user.isSuperadmin) {
        await _tokens.clear();
        return null;
      }
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) return null;
      rethrow;
    }
  }

  /// Re-reads the signed-in user, e.g. after buying a plan.
  Future<void> refresh() async {
    if (state.value == null) return;
    state = AsyncData(await _repo.me());
  }

  Future<void> login(String login, String password) async {
    await _completeSignIn(await _repo.login(login: login, password: password));
  }

  Future<void> register({
    required String name,
    required String email,
    String? mobile,
    required String password,
    String coachType = 'coach',
  }) async {
    await _completeSignIn(
      await _repo.register(name: name, email: email, mobile: mobile, password: password, coachType: coachType),
    );
  }

  /// Replaces the signed-in user after profile changes such as a new avatar.
  void setUser(AppUser user) => state = AsyncData(user);

  Future<void> deleteAccount({String? password}) async {
    await _repo.deleteAccount(password: password);
    await _tokens.clear();
    state = const AsyncData(null);
  }

  Future<void> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await google.initialize(
        serverClientId: Env.googleServerClientId.isEmpty ? null : Env.googleServerClientId,
      );
      _googleInitialized = true;
    }
    if (!google.supportsAuthenticate()) {
      throw ApiException('Google sign-in is not available on this platform.');
    }

    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      throw ApiException(e.description ?? 'Google sign-in failed.');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) throw ApiException('Google did not return an ID token.');
    await _completeSignIn(await _repo.loginWithGoogle(idToken));
  }

  Future<void> updateProfile({required String name, String? mobile}) async {
    state = AsyncData(await _repo.updateProfile(name: name, mobile: mobile));
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {
      // The local session is cleared regardless of whether the server call succeeds.
    }
    await _tokens.clear();
    state = const AsyncData(null);
  }

  Future<void> _completeSignIn(AuthResult result) async {
    ref.read(sessionNoticeProvider.notifier).clear();
    if (result.user.isSuperadmin) {
      await _tokens.write(result.token);
      try {
        await _repo.logout();
      } catch (_) {
        // The token is discarded locally either way.
      }
      await _tokens.clear();
      throw ApiException('Superadmin accounts sign in to the web admin panel, not the mobile app.');
    }
    await _tokens.write(result.token);
    state = AsyncData(result.user);
  }
}
