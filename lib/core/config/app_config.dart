import 'dart:io';

class AppConfig {
  static const String _lanIp = '192.168.88.237';
  static const int _port = 3001;

  static String get apiBaseUrl {
    // Android (máy thật + emulator) đều dùng IP LAN của laptop
    if (Platform.isAndroid) {
      return 'http://$_lanIp:$_port';
    }
    // iOS simulator / desktop
    return 'http://localhost:$_port';
  }

  static String get socketUrl => apiBaseUrl;
}
