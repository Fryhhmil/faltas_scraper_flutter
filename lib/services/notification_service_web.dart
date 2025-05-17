// Arquivo de stub para plataformas não-Android
// Esta classe fornece implementações vazias dos métodos do AndroidAlarmManager
// para evitar erros em plataformas não suportadas

class AndroidAlarmManager {
  static Future<bool> initialize() async {
    return true;
  }

  static Future<bool> periodic(
    Duration duration,
    int id,
    Function callback, {
    bool exact = false,
    bool wakeup = false,
    bool rescheduleOnReboot = false,
    DateTime? startAt,
  }) async {
    return true;
  }

  static Future<bool> oneShot(
    Duration duration,
    int id,
    Function callback, {
    bool exact = false,
    bool wakeup = false,
    bool rescheduleOnReboot = false,
    DateTime? startAt,
  }) async {
    return true;
  }
  
  static Future<bool> cancel(int id) async {
    return true;
  }
}
