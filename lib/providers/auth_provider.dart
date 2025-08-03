
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:atproto/atproto.dart' as atp;
import 'package:atproto_core/atproto_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<Session?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<Session?>> {
  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadSession();
  }

  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  Future<void> _loadSession() async {
    final sessionJson = await _storage.read(key: 'session');
    if (sessionJson != null) {
      final sessionMap = jsonDecode(sessionJson);
      state = AsyncValue.data(Session.fromJson(sessionMap));
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String handle, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await atp.createSession(
        identifier: handle,
        password: password,
        service: dotenv.env['BLUESKY_SERVICE_URL']!,
      );
      final session = response.data;
      await _storage.write(key: 'session', value: jsonEncode(session.toJson()));
      state = AsyncValue.data(session);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'session');
    state = const AsyncValue.data(null);
  }
}
