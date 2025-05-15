import '../models/login_model.dart';
import '../models/falta_model.dart';
import '../models/horario_model.dart';

/// Interface para serviços de API
abstract class ApiInterface {
  Future<String> login(LoginModel loginData);
  Future<List<FaltaModel>> buscarFaltas(String cookie);
  Future<HorarioAlunoModel> buscarHorario(String cookie);
}
