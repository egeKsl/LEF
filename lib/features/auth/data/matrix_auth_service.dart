import 'package:matrix/matrix.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class MatrixAuthService {
  Client? _client;
  bool _isInitialized = false;

  Client get client {
    if (!_isInitialized || _client == null) {
      throw StateError("Matrix Client is not initialized yet. Call init() first.");
    }
    return _client!;
  }

  /// Initializes the Matrix Client with local database support.
  Future<void> init() async {
    if (_isInitialized) return;

    final directory = await getApplicationSupportDirectory();
    final dbPath = p.join(directory.path, 'secure_matrix_store.db');

    final database = await MatrixSdkDatabase.init(
      'secure_matrix_store',
      database: await openDatabase(dbPath),
      fileStorageLocation: directory.uri,
    );

    _client = Client(
      'MatrixSecureAuthClient',
      database: database,
    );
    await _client!.init();
    _isInitialized = true;

    // CRITICAL: Automatically kickstart background synchronization loop 
    // if an active secure token is already stored in the database.
    if (_client!.isLogged()) {
      _client!.backgroundSync = true;
    }
  }

  /// Returns true when a persisted Matrix session is available locally.
  Future<bool> hasActiveSession() async {
    await init();
    return _client!.isLogged();
  }

  Uri _normalizeUrl(String homeserver) {
    String url = homeserver.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('localhost') || url.startsWith('127.0.0.1') || url.startsWith('10.0.2.2') || url.startsWith('192.168.')) {
        url = 'http://$url';
      } else {
        url = 'https://$url';
      }
    }
    return Uri.parse(url);
  }

  /// GENERATE_KEY: Zero-Knowledge Registration and Cryptographic Device Key Generation.
  Future<String> register({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    await init();
    final homeserverUri = _normalizeUrl(homeserver);

    await _client!.checkHomeserver(homeserverUri);

    final loginResponse = await _client!.register(
      username: username,
      password: password,
      auth: AuthenticationData(type: 'm.login.dummy'),
    );

    // Start streaming incoming network payloads immediately following successful registration.
    _client!.backgroundSync = true;

    return loginResponse.userId ?? username;
  }

  /// IDENTITY_LOGIN: Establish session node link using existing client credentials.
  Future<String> login({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    await init();
    final homeserverUri = _normalizeUrl(homeserver);

    await _client!.checkHomeserver(homeserverUri);

    final loginResponse = await _client!.login(
      LoginType.mLoginPassword,
      identifier: AuthenticationUserIdentifier(user: username),
      password: password,
    );

    // Start streaming incoming network payloads immediately following successful verification.
    _client!.backgroundSync = true;

    return loginResponse.userId ?? username;
  }

  /// LOGOUT: Sever the current secure link connection and purge local operational caches.
  Future<void> logout() async {
    if (_isInitialized && _client != null && _client!.isLogged()) {
      await _client!.logout();
    }
  }
}