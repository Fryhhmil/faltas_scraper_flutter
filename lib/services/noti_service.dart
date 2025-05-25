import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Inicializa as notificações
  Future<void> initNotificarions() async {
    if (_isInitialized) return; // evitar reinitialização

    tz.initializeTimeZones();
    final String timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone));

    // Inicializar Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Inicializar IOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // init settings
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inicializar notificações
    await notificationsPlugin.initialize(settings);
  }

  // detalhes da notificação
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
        android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // MOSTRAR NOTIFICACOES
  Future<void> showNotifications({
    int id = 0, 
    required String title, 
    required String body
  }) async {
    await notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails(),
    );
  }

  // SCHEDULE NOTIFICATIONS
  Future<void> scheduleNotification({
    int id = 0, 
    required String title, 
    required String body,
    required int hora,
    required int minuto,
  }) async {
    // Pegar hora atual
    final now = tz.TZDateTime.now(tz.local);
    
    // Hora da notificacao
    final scheduledNotificationDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hora,
      minuto,
    );

    // Schedule notification
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledNotificationDateTime,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      //repetir
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancelar notificacao
  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
  }

  // Cancelar todas as notificacoes
  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }

} 