import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'storage_service.dart';

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Inicializa as notificações
  Future<void> initNotificarions() async {
    if (_isInitialized) return; // evitar reinitialização

    tz.initializeTimeZones();
    final String currentTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimezone));

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
    _isInitialized = true;
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
    var scheduledNotificationDateTime = tz.TZDateTime(
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

      // Android
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

  // Criar e agendar notificação de lembrete de faltas disponíveis
  Future<void> scheduleFaltasDisponiveisNotification({
    int id = 2,
    required int hora,
    required int minuto,
  }) async {
    final storageService = StorageService();
    final horario = await storageService.getHorario();
    
    if (horario == null) return;
    
    // Pegar hora atual
    final now = tz.TZDateTime.now(tz.local);
    
    // Hora da notificacao
    var scheduledNotificationDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hora,
      minuto,
    );
    
    // Se o horário já passou hoje, agenda para amanhã
    if (now.isAfter(scheduledNotificationDateTime)) {
      scheduledNotificationDateTime = scheduledNotificationDateTime.add(const Duration(days: 1));
    }
    
    // Schedule notification com verificação diária
    await notificationsPlugin.zonedSchedule(
      id,
      'Lembrete de Faltas Disponíveis',
      'Verificando faltas disponíveis para hoje...',
      scheduledNotificationDateTime,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'check_faltas_disponiveis',
    );
  }

  // Mostrar notificação de faltas disponíveis para o dia atual
  Future<void> showFaltasDisponiveisNotification() async {
    final storageService = StorageService();
    final horario = await storageService.getHorario();
    
    if (horario == null) return;
    
    final hoje = DateTime.now().weekday;
    
    // Se for fim de semana, não envia notificação
    if (hoje > 5) return;
    
    final podeFaltarHoje = horario.getFaltasRestantes(hoje);
    final materias = horario.getMateriasDoDia(hoje);
    
    // Texto personalizado para o lembrete de faltas
    String mensagem;
    if (podeFaltarHoje == 0) {
      mensagem = '⚠️ Atenção! Você não pode faltar hoje nas aulas de $materias.';
    } else if (podeFaltarHoje == 1) {
      mensagem = '📚 Lembrete: Você só pode faltar mais 1 vez hoje nas aulas de $materias. Aproveite bem sua presença!';
    } else {
      mensagem = '📚 Lembrete: Você pode faltar até $podeFaltarHoje vezes hoje nas aulas de $materias.';
    }
    
    // Mostrar notificação
    await showNotifications(
      id: 3,
      title: 'Lembrete de Faltas Disponíveis',
      body: mensagem,
    );
  }
}