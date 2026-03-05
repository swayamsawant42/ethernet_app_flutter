import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class ApiConfig {
  static const String _webBaseUrl = "http://157.245.162.143:3000/api/v1";
  static const String _androidEmulatorBaseUrl = "http://157.245.162.143:3000/api/v1";
  static const String _lanBaseUrl = "http://157.245.162.143:3000/api/v1";

  static const Map<_Environment, String> _urls = {
    _Environment.web: _webBaseUrl,
    _Environment.androidEmulator: _androidEmulatorBaseUrl,
    _Environment.physicalDevice: _lanBaseUrl,
  };

  static set overrideBaseUrl(String? value) => _overrideBaseUrl = value;
  static String? _overrideBaseUrl;

  static String get baseUrl => _overrideBaseUrl?.isNotEmpty == true
      ? _overrideBaseUrl!
      : _urls[currentEnvironment]!;

  static _Environment get currentEnvironment {
    if (kIsWeb) return _Environment.web;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _preferEmulatorLoopback
          ? _Environment.androidEmulator
          : _Environment.physicalDevice;
    }
    return _Environment.physicalDevice;
  }

  static bool get _preferEmulatorLoopback => const bool.fromEnvironment(
    "USE_ANDROID_EMULATOR_LOOPBACK",
    defaultValue: false,
  );
}

enum _Environment { web, androidEmulator, physicalDevice }
