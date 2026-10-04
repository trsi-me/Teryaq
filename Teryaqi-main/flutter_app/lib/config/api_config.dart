import 'package:flutter/foundation.dart';

const String kAndroidEmulatorApiBase = 'http://192.168.8.141:8080';

const String _apiBaseFromEnv = String.fromEnvironment(
  'TERYAQI_API_BASE',
  defaultValue: '',
);

String defaultApiBaseUrl() {
  if (kIsWeb) return 'http://localhost:8080';
  if (defaultTargetPlatform == TargetPlatform.android) {
    final fromEnv = _apiBaseFromEnv.trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv.replaceAll(RegExp(r'/$'), '');
    }
    return kAndroidEmulatorApiBase;
  }
  return 'http://127.0.0.1:8080';
}
