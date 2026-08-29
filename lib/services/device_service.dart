import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  String? _cachedDeviceId;

  String getOsName() {
    if (defaultTargetPlatform == TargetPlatform.windows) return 'Windows';
    if (defaultTargetPlatform == TargetPlatform.linux) return 'Linux';
    if (defaultTargetPlatform == TargetPlatform.android) return 'Android';
    return 'Неизвестная ОС';
  }

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final deviceInfo = DeviceInfoPlugin();
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      _cachedDeviceId = androidInfo.id;
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      _cachedDeviceId = windowsInfo.deviceId;
    } else {
      final linuxInfo = await deviceInfo.linuxInfo;
      _cachedDeviceId = linuxInfo.machineId ?? const Uuid().v4();
    }
    
    return _cachedDeviceId!;
  }

  /// Получает IP через системные команды (ipconfig/ifconfig) или сокет (Android)
  Future<String> getIpAddress() async {
    try {
      if (Platform.isWindows) {
        return await _getIpFromIpconfig();
      } else if (Platform.isLinux) {
        return await _getIpFromIfconfig();
      } else if (Platform.isAndroid) {
        return await _getIpFromAndroid();
      }
    } catch (e) {
      // Игнорируем ошибки, вернем значение по умолчанию
    }
    return 'IP_не_определен';
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

  /// Linux: парсит вывод ip addr или ifconfig
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

  /// Android: используем UDP-сокет (Process.run на Android ограничен)
  Future<String> _getIpFromAndroid() async {
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      final ip = socket.address.address;
      await socket.close();
      if (ip.isNotEmpty && !ip.contains(':') && ip != '0.0.0.0') {
        return ip;
      }
    } catch (_) {}
    return 'IP_не_определен';
  }
}