import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'api_factory.dart';
import 'storage_service.dart';

// Import condicionalmente o dart:io apenas para plataformas não-web
import 'dart:io' if (dart.library.html) 'platform_stub.dart' show Platform;

// Importação condicional para Android
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart' if (dart.library.html) 'notification_service_web.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Estes campos são usados apenas nos métodos estáticos via instâncias locais

  // IDs para os alarmes
  static const int atualizacaoFaltasId = 1;
  static const int lembreteFaltasId = 2;

  Future<void> init() async {
    tz_data.initializeTimeZones();

    // Inicializa as notificações locais
    final InitializationSettings initializationSettings;
    
    if (!kIsWeb && Platform.isAndroid) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      initializationSettings = const InitializationSettings(
        android: initializationSettingsAndroid,
      );
    } else {
      // Para web e outras plataformas, usar configurações vazias
      initializationSettings = const InitializationSettings();
    }

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Só configura alarmes no Android
    if (!kIsWeb && Platform.isAndroid) {
      // Inicializa o gerenciador de alarmes
      await AndroidAlarmManager.initialize();

      // Agenda as tarefas recorrentes
      await configurarAtualizacaoAutomatica();
      await configurarLembreteDiario();
    }
  }

  // Configura a atualização automática das faltas com horário personalizável
  Future<void> configurarAtualizacaoAutomatica() async {
    final storageService = StorageService();
    final settings = await storageService.getNotificationSettings();
    
    // Se as notificações estiverem desativadas, não agenda
    if (!settings.notificacoesAtivas) return;
    
    final DateTime agora = DateTime.now();
    final DateTime horarioAtualizacao = DateTime(
      agora.year,
      agora.month,
      agora.day,
      settings.atualizacaoHora,
      settings.atualizacaoMinuto,
    );

    // Se o horário já passou hoje, agenda para amanhã
    final DateTime horarioEfetivo = agora.isAfter(horarioAtualizacao)
        ? horarioAtualizacao.add(const Duration(days: 1))
        : horarioAtualizacao;

    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      atualizacaoFaltasId,
      _atualizarFaltasCallback,
      startAt: horarioEfetivo,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  // Configura o lembrete diário com horário personalizável
  Future<void> configurarLembreteDiario() async {
    final storageService = StorageService();
    final settings = await storageService.getNotificationSettings();
    
    // Se as notificações estiverem desativadas, não agenda
    if (!settings.notificacoesAtivas) return;
    
    final DateTime agora = DateTime.now();
    final DateTime horarioLembrete = DateTime(
      agora.year,
      agora.month,
      agora.day,
      settings.lembreteHora,
      settings.lembreteMinuto,
    );

    // Se o horário já passou hoje, agenda para amanhã
    final DateTime horarioEfetivo = agora.isAfter(horarioLembrete)
        ? horarioLembrete.add(const Duration(days: 1))
        : horarioLembrete;

    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      lembreteFaltasId,
      _lembreteCallback,
      startAt: horarioEfetivo,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  // Callback para atualização das faltas (executado em segundo plano)
  @pragma('vm:entry-point')
  static Future<void> _atualizarFaltasCallback() async {
    final storageService = StorageService();
    final apiFactory = ApiFactory();
    final apiService = apiFactory.getApi();

    try {
      // Obtém o cookie salvo
      final cookie = await storageService.getCookie();
      if (cookie != null && cookie.isValid()) {
        // Busca as faltas atualizadas
        final faltas = await apiService.buscarFaltas(cookie.cookie);
        await storageService.saveFaltas(faltas);

        // Envia uma notificação informando que os dados foram atualizados
        await _mostrarNotificacao(
          'Faltas Atualizadas',
          'Seus dados de faltas foram atualizados automaticamente.',
        );
      }
    } catch (e) {
      print('Erro ao atualizar faltas: $e');
    }
  }

  // Callback para o lembrete diário (executado em segundo plano)
  @pragma('vm:entry-point')
  static Future<void> _lembreteCallback() async {
    final storageService = StorageService();

    try {
      // Obtém o horário salvo
      final horario = await storageService.getHorario();

      if (horario != null) {
        final hoje = DateTime.now().weekday;
        final faltasRestantes = horario.getFaltasRestantes(hoje);
        final materias = horario.getMateriasDoDia(hoje);

        // Envia uma notificação com as informações do dia
        await _mostrarNotificacao(
          'Aulas de Hoje',
          'Você tem aulas de $materias hoje e pode faltar $faltasRestantes vezes.',
        );
      }
    } catch (e) {
      print('Erro ao mostrar lembrete: $e');
    }
  }

  // Função auxiliar para mostrar notificações
  static Future<void> _mostrarNotificacao(String titulo, String corpo) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'faltas_channel',
      'Faltas',
      channelDescription: 'Notificações sobre faltas',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      titulo,
      corpo,
      platformChannelSpecifics,
    );
  }

  // Método para mostrar notificação imediatamente (para testes)
  Future<void> mostrarNotificacaoTeste() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      await _mostrarNotificacao(
        'Teste de Notificação',
        'Esta é uma notificação de teste.',
      );
    } else {
      // Em plataformas não suportadas, apenas imprime no console
      print('Notificação de teste (plataforma não suportada): Esta é uma notificação de teste.');
    }
  }
  
  // Método para reconfigurar as notificações após mudança nas configurações
  Future<void> reconfigurarNotificacoes() async {
    if (!kIsWeb && Platform.isAndroid) {
      // Cancela os alarmes existentes
      await AndroidAlarmManager.cancel(atualizacaoFaltasId);
      await AndroidAlarmManager.cancel(lembreteFaltasId);
      
      // Reconfigura com os novos horários
      await configurarAtualizacaoAutomatica();
      await configurarLembreteDiario();
    }
  }
}
