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

  // Надежный способ получения IP для Windows, Linux и Android
  Future<String> getIpAddress() async {
    try {
      // Создаем UDP-сокет и "подключаем" его к внешнему IP (данные не отправляются)
      final socket = await Socket.connect('8.8.8.8', 53); 
      final ip = socket.address.address;
      await socket.close();
      
      // Проверка на случай, если вернется IPv6 или странный формат
      if (ip.isEmpty || ip == '0.0.0.0') {
        return 'IP_не_определен';
      }
      return ip;
    } catch (e) {
      return 'IP_не_определен';
    }
  }
}