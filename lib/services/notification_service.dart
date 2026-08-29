import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  // Проверяем платформу через kIsWeb и Platform
  bool get isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Инициализация локальных уведомлений
  Future<void> init() async {
    if (_isInitialized) return;

    // Инициализируем только на мобильных платформах
    if (!isMobilePlatform) {
      _isInitialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Запрос разрешений для Android 13+
    await _requestPermissions();

    _isInitialized = true;
  }

  /// Запрос разрешений на уведомления
  Future<void> _requestPermissions() async {
    if (!isMobilePlatform) return;

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  /// Обработка нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    // Можно добавить навигацию при клике на уведомление
  }

  /// Показ локального уведомления (для Android)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!isMobilePlatform) return;
    
    if (!_isInitialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'ticketik_channel',
      'Ticketik Notifications',
      channelDescription: 'Уведомления о новых заявках',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      autoCancel: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Показ уведомления о новой заявке
  Future<void> showNewTicketNotification({
    required String description,
    required String room,
    required String pcNumber,
  }) async {
    await showNotification(
      title: '📬 Новая заявка',
      body: '$description\nКабинет: $room, ПК: $pcNumber',
      payload: 'new_ticket',
    );
  }

  /// Показ уведомления об изменении статуса
  Future<void> showStatusChangeNotification({
    required String description,
    required String status,
  }) async {
    final statusText = _getStatusText(status);
    await showNotification(
      title: '🔄 Статус заявки изменён',
      body: '$description\nНовый статус: $statusText',
      payload: 'status_change',
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'new':
        return 'Новая';
      case 'in_progress':
        return 'В работе';
      case 'done':
        return 'Выполнено';
      default:
        return status;
    }
  }

  /// Настройка Firebase Messaging (для push-уведомлений) - ТОЛЬКО для Android
  Future<void> setupFirebaseMessaging() async {
    if (!isMobilePlatform) return;
    
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Запрос разрешения для iOS и Android 13+
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Получение токена устройства
    String? token = await messaging.getToken();

    // Обработка сообщений в фоне
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Обработка сообщений в форегround
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'Уведомление',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // Обработка нажатия на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Можно добавить навигацию при клике
    });
  }

  /// Удалить все уведомления
  Future<void> cancelAllNotifications() async {
    if (!isMobilePlatform) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Удалить конкретное уведомление
  Future<void> cancelNotification(int id) async {
    if (!isMobilePlatform) return;
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}

/// Firebase background handler - должна быть на верхнем уровне
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Можно добавить обработку фоновых сообщений
}
