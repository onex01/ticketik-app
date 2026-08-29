import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  String? _cachedDeviceId;
  String? _cachedOsName;

  String getOsName() {
    if (_cachedOsName != null) return _cachedOsName!;
    
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _cachedOsName = 'Windows';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      _cachedOsName = 'Linux';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      _cachedOsName = 'Android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      _cachedOsName = 'iOS';
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      _cachedOsName = 'macOS';
    } else {
      _cachedOsName = 'Неизвестная ОС';
    }
    
    return _cachedOsName!;
  }

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        _cachedDeviceId = androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        _cachedDeviceId = windowsInfo.deviceId;
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        _cachedDeviceId = linuxInfo.machineId ?? const Uuid().v4();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _cachedDeviceId = iosInfo.identifierForVendor;
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macosInfo = await deviceInfo.macOsInfo;
        _cachedDeviceId = macosInfo.systemGUID ?? const Uuid().v4();
      } else {
        _cachedDeviceId = const Uuid().v4();
      }
    } catch (e) {
      _cachedDeviceId = const Uuid().v4();
    }
    
    return _cachedDeviceId!;
  }

  Future<String> getIpAddress() async {
    final networkInfo = NetworkInfo();
    
    try {
      // Пробуем получить IP через WiFi
      String? ip = await networkInfo.getWifiIP();
      
      if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') {
        return ip;
      }
      
      // Если WiFi не доступен, пробуем альтернативные методы для разных платформ
      if (defaultTargetPlatform == TargetPlatform.windows || 
          defaultTargetPlatform == TargetPlatform.linux) {
        // Для Windows/Linux пытаемся получить IP через сокет
        try {
          final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
          final localIp = socket.address.address;
          await socket.close();
          if (localIp.isNotEmpty && localIp != '0.0.0.0') {
            return localIp;
          }
        } catch (e) {
          // Игнорируем ошибку сокета
        }
      }
      
      // Последняя попытка для Android
      if (defaultTargetPlatform == TargetPlatform.android) {
        // network_info_plus на Android иногда требует больше времени
        await Future.delayed(const Duration(milliseconds: 1000));
        ip = await networkInfo.getWifiIP();
        if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') {
          return ip;
        }
      }
    } catch (e) {
      // Ловим любые ошибки сети
    }
    
    return 'IP_не_определен';
  }
}