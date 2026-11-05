import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final storage = TokenStorage(const FlutterSecureStorage());
  ref.onDispose(storage.dispose);
  return storage;
});

/// Why the app signed the user out on its own, shown on the Sign In screen.
enum SessionNotice { expired, deactivated }

final sessionNoticeProvider = NotifierProvider<SessionNoticeState, SessionNotice?>(SessionNoticeState.new);

class SessionNoticeState extends Notifier<SessionNotice?> {
  @override
  SessionNotice? build() => null;

  void show(SessionNotice notice) => state = notice;

  void clear() => state = null;
}

class TokenStorage {
  TokenStorage(this._storage);

  static const _key = 'auth_token';

  final FlutterSecureStorage _storage;
  final _clearedController = StreamController<SessionNotice?>.broadcast();
  String? _cached;
  bool _loaded = false;

  /// Emits when the token is cleared. Carries a reason when the server ended the session.
  Stream<SessionNotice?> get onCleared => _clearedController.stream;

  Future<String?> read() async {
    if (!_loaded) {
      _cached = await _storage.read(key: _key);
      _loaded = true;
    }
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    _loaded = true;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear({SessionNotice? reason}) async {
    final hadToken = _cached != null;
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _key);
    if (hadToken) _clearedController.add(reason);
  }

  void dispose() => _clearedController.close();
}
