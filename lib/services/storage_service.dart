import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_model.dart';
import '../models/falta_model.dart';
import '../models/horario_model.dart';
import '../models/notification_settings_model.dart';
import '../models/contexto_aluno.dart';

class StorageService {
  static const String _loginKey = 'login_data';
  static const String _cookieKey = 'cookie_data';
  static const String _faltasKey = 'faltas_data';
  static const String _horarioKey = 'horario_data';
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _selectedContextKey = 'selected_context';

  // Login
  Future<void> saveLogin(LoginModel login) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginKey, jsonEncode(login.toJson()));
  }

  Future<LoginModel?> getLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final loginString = prefs.getString(_loginKey);
    if (loginString == null) return null;
    
    try {
      return LoginModel.fromJson(jsonDecode(loginString));
    } catch (e) {
      return null;
    }
  }

  // Cookie
  Future<void> saveCookie(CookieModel cookie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, jsonEncode(cookie.toJson()));
  }

  Future<CookieModel?> getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    final cookieString = prefs.getString(_cookieKey);
    if (cookieString == null) return null;
    
    try {
      return CookieModel.fromJson(jsonDecode(cookieString));
    } catch (e) {
      return null;
    }
  }

  Future<void> removeCookie() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
  }

  // Faltas
  Future<void> saveFaltas(List<FaltaModel> faltas) async {
    final prefs = await SharedPreferences.getInstance();
    final faltasJson = faltas.map((f) => f.toJson()).toList();
    await prefs.setString(_faltasKey, jsonEncode(faltasJson));
  }

  Future<List<FaltaModel>> getFaltas() async {
    final prefs = await SharedPreferences.getInstance();
    final faltasString = prefs.getString(_faltasKey);
    if (faltasString == null) return [];
    
    try {
      final List<dynamic> faltasJson = jsonDecode(faltasString);
      return faltasJson.map((json) => FaltaModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Horário
  Future<void> saveHorario(HorarioAlunoModel horario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_horarioKey, jsonEncode(horario.toJson()));
  }

  Future<HorarioAlunoModel?> getHorario() async {
    final prefs = await SharedPreferences.getInstance();
    final horarioString = prefs.getString(_horarioKey);
    if (horarioString == null) return null;
    
    try {
      return HorarioAlunoModel.fromJson(jsonDecode(horarioString));
    } catch (e) {
      return null;
    }
  }
  
  // Configurações de Notificação
  Future<void> saveNotificationSettings(NotificationSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationSettingsKey, jsonEncode(settings.toJson()));
  }
  
  Future<NotificationSettingsModel> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_notificationSettingsKey);
    if (settingsString == null) return NotificationSettingsModel.defaultSettings();
    
    try {
      return NotificationSettingsModel.fromJson(jsonDecode(settingsString));
    } catch (e) {
      return NotificationSettingsModel.defaultSettings();
    }
  }

  // Contexto selecionado
  Future<void> saveSelectedContext(ContextoAluno contexto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedContextKey, jsonEncode(contexto.toJson()));
  }

  Future<ContextoAluno?> getSelectedContext() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_selectedContextKey);
    if (s == null) return null;
    try {
      return ContextoAluno.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> removeSelectedContext() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedContextKey);
  }
}
