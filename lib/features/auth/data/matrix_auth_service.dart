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
    _isInitialized = true;
  }

  /// Normalizes the server address format (e.g., matrix.org -> https://matrix.org)
  Uri _normalizeUrl(String homeserver) {
    String url = homeserver.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
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

    // FIX: Changed AuthenticationTypes.password to 'm.login.dummy' to match 
    // the local Synapse non-verification registration requirements.
    final loginResponse = await _client!.register(
      username: username,
      password: password,
      auth: AuthenticationData(type: 'm.login.dummy'),
    );

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

    return loginResponse.userId ?? username;
  }

  /// LOGOUT: Sever the current secure link connection and purge local operational caches.
  Future<void> logout() async {
    if (_isInitialized && _client != null && _client!.isLogged()) {
      await _client!.logout();
    }
  }
}
