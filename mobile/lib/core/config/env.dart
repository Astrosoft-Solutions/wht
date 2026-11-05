import 'package:flutter/foundation.dart';

class Env {
  Env._();

  static const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// OAuth "Web application" client ID; Google returns an ID token whose audience is this ID.
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Android emulators reach the host machine through 10.0.2.2 instead of localhost.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  /// The React web panel served by the same Laravel app, used for plan purchases on web.
  static String get adminPanelUrl {
    final api = Uri.parse(apiBaseUrl);
    return api.replace(path: '/admin/coach/plans').toString();
  }

  /// Laravel builds storage URLs from APP_URL (localhost), which a phone or emulator cannot reach,
  /// so media URLs pointing at localhost are rewritten to the API host.
  static String resolveMediaUrl(String url) {
    final media = Uri.tryParse(url);
    if (media == null) return url;
    if (media.host != 'localhost' && media.host != '127.0.0.1') return url;
    final api = Uri.parse(apiBaseUrl);
    return media.replace(scheme: api.scheme, host: api.host, port: api.port).toString();
  }
}
