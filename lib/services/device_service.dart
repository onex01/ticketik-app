import 'dart:io' show Platform, Process;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  String? _cachedDeviceId;
  String? _cachedIpAddress;

  /// Проверяет, мобильная ли платформа (Android/iOS)
  bool get isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  String getOsName() {
    if (defaultTargetPlatform == TargetPlatform.windows) return 'Windows';
    if (defaultTargetPlatform == TargetPlatform.linux) return 'Linux';
    if (defaultTargetPlatform == TargetPlatform.android) return 'Android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'iOS';
    if (defaultTargetPlatform == TargetPlatform.macOS) return 'macOS';
    return 'Неизвестная ОС';
  }

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final deviceInfo = DeviceInfoPlugin();
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      _cachedDeviceId = androidInfo.id;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _cachedDeviceId = iosInfo.identifierForVendor ?? const Uuid().v4();
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      _cachedDeviceId = windowsInfo.deviceId;
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      _cachedDeviceId = linuxInfo.machineId ?? const Uuid().v4();
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macInfo = await deviceInfo.macOsInfo;
      _cachedDeviceId = macInfo.systemGUID ?? const Uuid().v4();
    } else {
      _cachedDeviceId = const Uuid().v4();
    }
    
    return _cachedDeviceId!;
  }

  /// Получает IP-адрес в зависимости от платформы
  /// На мобильных устройствах использует network_info_plus
  /// На ПК использует системные команды
  Future<String> getIpAddress() async {
    if (_cachedIpAddress != null) return _cachedIpAddress!;

    try {
      if (isMobilePlatform) {
        // На мобильных используем библиотеку network_info_plus
        final info = NetworkInfo();
        final ip = await info.getWifiIP();
        if (ip != null && ip.isNotEmpty) {
          _cachedIpAddress = ip;
          return _cachedIpAddress!;
        }
      } else if (Platform.isWindows) {
        _cachedIpAddress = await _getIpFromIpconfig();
        return _cachedIpAddress!;
      } else if (Platform.isLinux) {
        _cachedIpAddress = await _getIpFromIfconfig();
        return _cachedIpAddress!;
      } else if (Platform.isMacOS) {
        _cachedIpAddress = await _getIpFromIfconfig();
        return _cachedIpAddress!;
      }
    } catch (e) {
      // Игнорируем ошибки, вернем значение по умолчанию
    }
    
    _cachedIpAddress = 'IP_не_определен';
    return _cachedIpAddress!;
  }

  /// Windows: парсит вывод ipconfig
  Future<String> _getIpFromIpconfig() async {
    final result = await Process.run('ipconfig', []);
    if (result.exitCode != 0) return 'IP_не_определен';
    
    final output = result.stdout.toString();
    final lines = output.split('\n');
    
    for (final line in lines) {
      // Ищем строку вида "IPv4-адрес. . . . . . . . . . . . : 192.168.1.50"
      if (line.contains('IPv4') || line.contains('IPv4 Address')) {
        final match = RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})').firstMatch(line);
        if (match != null) {
          final ip = match.group(1)!;
          // Фильтруем мусорные адреса
          if (!ip.startsWith('169.254.') && !ip.startsWith('127.') && ip != '0.0.0.0') {
            return ip;
          }
        }
      }
    }
    return 'IP_не_определен';
  }

  /// Linux/macOS: парсит вывод ip addr или ifconfig
  Future<String> _getIpFromIfconfig() async {
    // Пробуем современную команду 'ip addr'
    try {
      final result = await Process.run('ip', ['addr', 'show']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})').firstMatch(output);
        if (match != null) {
          final ip = match.group(1)!;
          if (!ip.startsWith('169.254.') && !ip.startsWith('127.') && ip != '0.0.0.0') {
            return ip;
          }
        }
      }
    } catch (_) {}

    // Резерв: старая команда ifconfig
    try {
      final result = await Process.run('ifconfig', []);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})').firstMatch(output);
        if (match != null) {
          final ip = match.group(1)!;
          if (!ip.startsWith('169.254.') && !ip.startsWith('127.') && ip != '0.0.0.0') {
            return ip;
          }
        }
      }
    } catch (_) {}

    return 'IP_не_определен';
  }

  /// Сброс кэша IP (если нужно обновить)
  void resetIpCache() {
    _cachedIpAddress = null;
  }
}
