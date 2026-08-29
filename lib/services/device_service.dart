import 'package:network_info_plus/network_info_plus.dart';
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

  Future<String> getIpAddress() async {
    final networkInfo = NetworkInfo();
    // Делаем небольшую паузу, чтобы сеть успела инициализироваться
    await Future.delayed(const Duration(milliseconds: 500));
    String? ip = await networkInfo.getWifiIP();
    
    // Если WiFi нет, пробуем получить IP через альтернативный метод (для Ethernet)
    if (ip == null || ip.isEmpty) {
       // network_info_plus иногда не видит Ethernet на Linux/Windows. 
       // Пока оставим заглушку, но пользователь увидит предупреждение.
       return 'IP_не_определен_проверьте_сеть';
    }
    return ip;
  }
}