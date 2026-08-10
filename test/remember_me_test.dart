// Exercises the "remember me" login → cold-start session-restore chain
// end-to-end: PlatformClient.login persisting (or not) a refresh token via
// AppPrefs' secure storage, and PlatformClient.tryRestoreSession — called
// fresh, with no in-memory access token, exactly like a real app cold start
// — exchanging a persisted refresh token for a new access token.
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shadow/services/app_prefs.dart';
import 'package:shadow/services/platform_client.dart';

/// In-memory fake standing in for the OS-backed secure storage (Android
/// Keystore / iOS Keychain) so this test can run on the desktop test VM.
class _FakeSecureStorage extends FlutterSecureStoragePlatform {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async =>
      _store[key];

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async =>
      _store.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    _store.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async =>
      Map.of(_store);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    _store.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStoragePlatform.instance = _FakeSecureStorage();
    // Dart tests share one isolate, so PlatformClient's in-memory access
    // token would otherwise leak between tests — reset it to genuinely
    // simulate a fresh app process for each test below.
    PlatformClient.resetForTesting();
  });

  test('login(rememberMe: true) persists a refresh token', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/auth/login');
      return http.Response(
        '{"accessToken":"acc-1","refreshToken":"ref-1","user":{}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await http.runWithClient(
      () => PlatformClient.login('a@b.com', 'pw', rememberMe: true),
      () => client,
    );

    expect(result.isSuccess, true);
    expect(await AppPrefs.getRefreshToken(), 'ref-1');
  });

  test('login(rememberMe: false) stores no refresh token', () async {
    final client = MockClient((request) async {
      return http.Response(
        '{"accessToken":"acc-2","refreshToken":"ref-2","user":{}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await http.runWithClient(
      () => PlatformClient.login('a@b.com', 'pw', rememberMe: false),
      () => client,
    );

    expect(result.isSuccess, true);
    expect(await AppPrefs.getRefreshToken(), null);
  });

  test('tryRestoreSession with no stored refresh token returns false',
      () async {
    final client = MockClient((request) async {
      fail('should not call the network with no stored refresh token');
    });

    final restored = await http.runWithClient(
      () => PlatformClient.tryRestoreSession(),
      () => client,
    );

    expect(restored, false);
  });

  test(
      'a cold start (no in-memory access token) restores the session from '
      'a persisted refresh token via /auth/refresh', () async {
    // Seeds secure storage directly, without calling login() in this test,
    // to simulate "a previous process logged in with remember-me, was
    // killed, and this is the next launch" — PlatformClient's in-memory
    // access token is genuinely unset here, same as a real cold start.
    await AppPrefs.setRefreshToken('ref-cold-start');

    final client = MockClient((request) async {
      expect(request.url.path, '/api/auth/refresh');
      expect(request.body.contains('ref-cold-start'), true);
      return http.Response(
        '{"accessToken":"acc-fresh"}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final restored = await http.runWithClient(
      () => PlatformClient.tryRestoreSession(),
      () => client,
    );

    expect(restored, true);
    expect(await PlatformClient.isLoggedIn, true);
  });

  test(
      'a rejected refresh token (expired/invalid) clears it and reports '
      'not logged in', () async {
    await AppPrefs.setRefreshToken('ref-expired');

    final client = MockClient((request) async {
      return http.Response('{"error":"invalid"}', 401,
          headers: {'content-type': 'application/json'});
    });

    final restored = await http.runWithClient(
      () => PlatformClient.tryRestoreSession(),
      () => client,
    );

    expect(restored, false);
    expect(await AppPrefs.getRefreshToken(), null);
  });
}
